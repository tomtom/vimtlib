#!/usr/bin/env ruby
# vimdedoc -- An ill-conceived casual VimL source code documenter
# @Author:      Tom Link (micathom at gmail com)
# @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
# @Created:     2007-07-25.
# @Last Change: 2010-04-25.
# @Revision:    501


require 'yaml'
require 'logger'
require 'optparse'
require 'cgi'


class VimDedoc
    VERSION = '1.0.0'

    class AppLog
        def initialize(output=$stdout)
            @output = output
            $logger = Logger.new(output)
            $logger.progname = 'vimdedoc'
            $logger.datetime_format = "%H:%M:%S"
            set_level
        end

        def set_level
            if $DEBUG
                $logger.level = Logger::DEBUG
            elsif $VERBOSE
                $logger.level = Logger::INFO
            else
                $logger.level = Logger::WARN
            end
        end
    end
    
    def initialize(outfile=1, sources=[])
        @logger    = AppLog.new
        @outfile   = outfile
        @repo      = nil
        @sources   = sources
        @template  = nil
        @update    = false
        @docs      = {}
        @config    = {}
        @fdocs     = {}
        @toc       = []
        @outformat = nil
        @insyntax  = nil
        @filetypes = {
            :general => {
                :entry_rx => /^\s*((function|def|class)\b.*)$/,
                :doc_rx   => /^[#%]\s+(.*)$/,
                :break_rx => /^\s*$/,
            },
            [:vim, '.vim'] => {
                # :entry_rx => /^\s*(((com|fun|TLet)\w*)\b!?\s*[^"]+).*$/,
                :entry_rx => /^\s*((com(mand)?|fun(ction)?|TLet)\b!?\s+.+?|let\s+.*?\s"\{\{\{\d|[incvoslx]?(nore)?map\s.*)\s*$/,
                # :eligible => lambda {|head| head =~ /^\S+\s+s:prototype\./ || head !~ /^\S+\s+(s:|<SID>)/},
                :eligible => lambda {|head| head =~ /^\S+\s+s:prototype\./ || head !~ /^\S+\s+(s:|<SID>|\w+#__)/},
                :doc_rx   => /^\s*"\s?(.*)$/,
                :break_rx => /^\s*$/,
                :process_head => lambda {|text, nodefault|
                    if text =~ /^\s*TLet!?\s*(\S*)\s*=\s*(.+?)\s*$/
                        if nodefault
                            text = $1
                        else
                            text = '%-30s (default: %s)' % [$1, $2.strip]
                        end
                    elsif text =~ /^\s*com.+?\s([[:upper:]]\S*)/
                        text = ":#$1"
                    elsif text =~ /^\s*fun.+?\s+s:prototype\.([[:upper:]].+?)\s*\(/
                        text = "prototype.#$1"
                    elsif text =~ /^\s*fun.+?\s((\S+#)*[[:upper:]].*?\s*\(.*?\))/
                        text = "#$1"
                    elsif text =~ /^\s*(([incvoslx])?(nore)?map)\s+(<buffer>\s*|<silent>\s*)*(\S+)\s+(.*)\s*$/
                        text = %{#{$2 && "#$2_"}#{$5} ... #{$6}}
                    elsif text =~ /^\s*let.+?(\S+)\s*=\s*(.*?)\s"\{\{\{\d\s*$/
                        if nodefault
                            text = $1
                        else
                            text = '%-30s (default: %s)' % [$1, $2.strip]
                        end
                    else
                        text = nil
                    end
                    text && text.gsub(/\s*\{{3}.*$/, '')
                },
                :process_doc => lambda {|text| text.gsub(/\s*\{{3}.*$/, '')},
                :tag => lambda {|head|
                    case head[0..1]
                    when 'co'
                        hm = head.match(/\s([[:upper:]]\S*)/)
                        if hm
                            ":#{hm[1]}"
                        else
                            $logger.warn "Couldn't parse comand: #{head}"
                            nil
                        end
                    when 'fu'
                        if head =~ /^fun.+?\s+s:prototype\.([[:upper:]].+?)/
                            false
                        elsif head =~ /^\s*fun.+?\s((\S+#)*[[:upper:]].+?)\s*\(/
                            $1 + '()'
                            # head.match(/^\S+\s+([^( ]+)/)[1] + '()'
                        end
                    else
                        if head =~ /^TLet/
                            head.match(/^\S+\s+(\S+)/)[1]
                        elsif head =~ /^\s*let\s+(\S+)/
                            $1
                        elsif head =~ /^\s*(([incvoslx])?(nore)?map)\s+(<buffer>\s*|<silent>\s*)*(\S+)\s+(.*)\s*$/
                            "#{$2 && "#$2_"}#$5"
                        else
                            $logger.warn "Unknown entry type: #{head}"
                        end
                    end
                },
            },
        }
    end

    def parse_arguments(args)
        outformats = methods.delete_if {|m| m !~ /^format_entry_/}.map {|m| m.to_s.sub(/^format_entry_/, '')}.sort
        syntax = @filetypes.keys.flatten.delete_if {|m| !m.instance_of?(Symbol)}.map {|s| s.to_s}.sort
        opts = OptionParser.new do |opts|
            opts.banner =  'Usage: vimdedoc [OPTIONS] FILES > OUTPUT'
            opts.separator ''
            opts.separator 'vimdedoc is a free software with ABSOLUTELY NO WARRANTY under'
            opts.separator 'the terms of the GNU General Public License version 2 or newer.'
            opts.separator ''
        
            opts.separator 'General Options:'
            opts.on('-c', '--config YAML', String, 'Config file') do |value|
                read_config(value)
            end

            opts.on('-f', '--format=FORMAT', outformats, 'Output format (default: vimhelp)') do |value|
                @outformat = value
            end

            opts.on('-o', '--output=FILENAME', String, 'Output destination') do |value|
                @outfile = value
            end

            opts.on('-s', '--syntax=SYNTAX', String, 'Input syntax') do |value|
                @insyntax = value.intern
            end

            opts.on('-t', '--template=FILENAME', String, 'Template file') do |value|
                @template = value
            end

            opts.on('-u', '--[no-]update', 'Create help file only if it is outdated') do |bool|
                @update = bool
            end
            
            opts.separator ''
            opts.separator 'Available output formats:'
            opts.separator outformats.join(', ')

            opts.separator ''
            opts.separator 'Known syntax:'
            opts.separator syntax.join(', ')

            opts.separator ''
            opts.separator 'Other Options:'
        
            opts.on('--debug', 'Show debug messages') do |v|
                $DEBUG   = true
                $VERBOSE = true
                @logger.set_level
            end
        
            opts.on('-v', '--verbose', 'Run verbosely') do |v|
                $VERBOSE = true
                @logger.set_level
            end
        
            opts.on_tail('-h', '--help', 'Show this message') do
                puts opts
                exit 1
            end
        end
        $logger.debug "command-line arguments: #{args}"
        @sources += opts.parse!(args)
        self
    end

    def read_config(file)
        if File.readable?(file)
            $logger.debug "Read configuration from #{file}"
            @config.merge!(YAML.load_file(file))
        end
    end

    def process
        outfile = filename_on_disk(@outfile)
        if @update and File.exist?(outfile)
            out_mtime = File.mtime(outfile)
            $logger.debug "MTIME: #{outfile}: #{out_mtime}"
            tpl_mtime = File.mtime(@template)
            $logger.debug "MTIME: #{@template}: #{tpl_mtime}"
            if tpl_mtime <= out_mtime and @sources.all? {|filename|
                filename = filename.strip
                filename1 = filename_on_disk(filename)
                mtime = File.mtime(filename1)
                older = mtime <= out_mtime
                $logger.debug "MTIME: #{filename}: #{mtime} => #{older}"
                older
            }
                $logger.info "Help is up to date: #{outfile}"
                return
            end
        end
        @sources.each do |file|
            collect_docs(file)
        end
        write_doc(format_doc)
    end

    def collect_docs(filename, filetype=nil)
        filetype   ||= check_filetype(File.extname(filename))
        filename1 = filename_on_disk(filename)
        if File.directory?(filename1)
            $logger.warn "Is a directory: #{filename}"
            return
        elsif !File.readable?(filename1)
            $logger.warn "Not readable: #{filename}"
            return
        end
        ftdef        = @filetypes[filetype]
        entry_rx     = ftdef[:entry_rx]
        doc_rx       = ftdef[:doc_rx]
        break_rx     = ftdef[:break_rx]
        process_doc  = ftdef[:process_doc]
        process_head = ftdef[:process_head]
        eligible     = ftdef[:eligible]
        tagger       = ftdef[:tag]
        $logger.debug "#{filetype}: #{ftdef.inspect}"
        @docs[filename]  ||= []
        @fdocs[filename] ||= []
        current_doc = []
        filedoc = false
        no_doc = false
        no_doc_default = false
        use_doc  = false
        use_tag  = nil
        use_head = nil
        use_name = nil
        tagprefix = ''
        @toc << filename
        file = File.readlines(filename1)
        file.each_with_index do |line, index|
            line.chomp!
            # p "DBG", line, line =~ break_rx, line =~ doc_rx, line =~ entry_rx
            if line =~ /^finish\s*$/
                break
            elsif line =~ break_rx
                if filedoc
                    @fdocs[filename] += current_doc
                    filedoc = false
                elsif use_doc
                    doc = compile_doc(current_doc, process_doc, 0)
                    @docs[filename] << {:type => :doc, :doc => doc, :tag => use_tag}
                    use_tag = nil
                    use_doc = false
                end
                current_doc = []
            elsif line =~ doc_rx
                m = $1
                if m =~ /^:nodoc:\s*$/
                    no_doc = true
                elsif m =~ /^:enddoc:\s*$/
                    break
                elsif m =~ /^:filedoc:\s*$/
                    filedoc = true
                elsif m =~ /^:doc:\s*$/
                    use_doc = true
                elsif m =~ /^:tagprefix( (.*?))?:\s*$/
                    tagprefix = $2
                elsif m =~ /^:tag:\s*(.+?)\s*$/
                    use_tag = $1
                elsif m =~ /^:def:\s*(.+?)\s*$/
                    use_head = $1
                elsif m =~ /^:display:\s*(.+?)\s*$/
                    use_name = $1
                elsif m =~ /^:nodefault:\s*$/
                    no_doc_default = true
                elsif m =~ /^:read:\s*(.+)$/
                    line = $1
                    redo
                else
                    current_doc << m
                end
            elsif line =~ entry_rx
                iline = $1
                if no_doc
                    no_doc = false
                elsif !eligible or eligible.call(line)
                    if use_head
                        head = use_head
                        use_head = nil
                    else
                        head = iline.strip
                    end
                    if use_tag
                        tag = use_tag
                        use_tag = nil
                    else
                        tag = tagger ? tagger.call(head) : entry[:head].match(/^\S+\s+([^( ]+)/)[1]
                    end
                    tag = tagprefix + tag unless tagprefix.empty?
                    if process_head
                        head = process_head.call(head, no_doc_default)
                        no_doc_default = false
                    end
                    doc = compile_doc(current_doc, process_doc)
                    unless tag.nil? and head.nil? and doc.empty?
                        @toc << [head, tag] unless tag.nil? || head.nil?
                        if use_name
                            head = use_name
                            use_name = nil
                        end
                        @docs[filename] << {:type => :entry, :head => head, :line => index, :doc => doc, :tag => tag}
                        # p "DBG", @docs[filename][-1]
                    end
                end
                current_doc = []
            end
        end
    end

    def compile_doc(doc, process_doc=nil, indent=4)
        doc = doc.dup << nil
        doc = format_lines(doc, indent)
        doc = process_doc.call(doc) if process_doc
        doc
    end

    def format_lines(lines, indent=4)
        m = "format_lines_#{@outformat || 'vimhelp'}"
        if respond_to?(m)
            send(m, lines, indent)
        else
            lines.map {|l| l && '    ' + l}.join("\n")
        end
    end

    def format_lines_vimhelp(lines, indent=0)
        # indent += 12 if indent > 0
        idc = false
        doc = lines.map do |l|
            if l
                if idc and (l =~ /^(<\s+)(.*)$/ or l =~ /^()(\S.*)$/)
                    idc = false
                    prefix  = $1.empty? ? '< ' : $1
                    prefix += ' ' * (indent - 2) if indent > 0
                    # prefix += ' ' * (indent) if indent > 0
                    l = $2
                else
                    prefix = indent > 0 ? ' ' * indent : ''
                end
                if l =~ / >\s*$/
                    idc = true
                end
                prefix + l
            end
        end
        doc.insert(doc.index(nil), '<') if idc
        doc.join("\n")
    end

    def format_lines_html(lines, indent=0)
        # indent += 12 if indent > 0
        idc = false
        doc = lines.map do |l|
            if l
                if l =~ /^<\s/
                    "</pre>\n#{CGI.escapeHTML(l[1..-1])}"
                elsif l =~ / >\s*$/
                    "#{CGI.escapeHTML(l.sub(/ >\s*$/, ''))}\n<pre>}"
                else
                    CGI.escapeHTML(l)
                end
            end
        end
        doc.join("\n")
    end

    def format_entry(*args)
        m = "format_entry_#{@outformat || 'vimhelp'}"
        if respond_to?(m)
            send(m, *args)
        else
            $logger.fatal "Unknown output format: #{outformat}"
            exit 5
        end
    end

    def format_entry_vimhelp(filename, doc)
        body = doc.map do |entry|
            rv = [entry[:tag] ? "                                                    *#{entry[:tag]}*" : nil]
            case entry[:type]
            when :doc
                rv << entry[:doc]
            else
                rv << entry[:head] << entry[:doc]
            end
            rv.join("\n")
        end
        fdoc = @fdocs[filename]
        fdoc = format_lines(fdoc.dup << nil, 0) if fdoc
        unless body.empty?
            ([
                '=' * 72,
                "#{filename}~",
                fdoc
             ] + body << nil
            ).join("\n")
        end
    end

    def format_entry_minimal(filename, doc)
        doc.map do |entry|
            "#{entry[:head]} [[#{filename}:#{entry[:line]}]]"
        end.join("\n")
    end

    def format_toc(*args)
        return if @toc.empty?
        m = "format_toc_#{@outformat || 'vimhelp'}"
        if respond_to?(m)
            send(m, *args)
        else
            $logger.fatal "Unknown output format: #{outformat}"
            exit 5
        end
    end

    def format_toc_vimhelp
        toc = @toc.map {|h, t| [h.match(/^[^([:space:]]+/)[0], t]}
        hl  = toc.map {|h, t| h.size}.max + 3
        hd  = nil
        ['=' * 72, 'Contents~', '', nil] +
            toc.map do |h, t|
                rv = case t
                     when String
                        "        %s %s |%s|" % [h, '.' * (hl - h.size), t]
                     when false
                        "        #{h}"
                     else
                         # hd = "    #{h}"
                         nil
                     end
                if rv and hd
                    rv = [hd, rv]
                    hd = nil
                end
                rv
            end.compact << '' << ''
    end

    def format_toc_minimal
    end

    def format_epilogue(*args)
        m = "format_epilogue_#{@outformat || 'vimhelp'}"
        if respond_to?(m)
            send(m, *args)
        else
            nil
        end
    end

    def format_epilogue_vimhelp(*args)
       %{\nvim:tw=78:fo=tcq2:isk=!-~,^*,^\|,^\":ts=8:ft=help:norl:}
    end

    def format_doc
        doc  = [
            format_toc,
            @sources.map do |filename|
                d = @docs[filename]
                format_entry(filename, d) if d
            end
        ].flatten.compact.join("\n")
        if @template
            tpl = File.read(@template)
            begin
                doc = tpl % doc
            rescue ArgumentError => e
                $stderr.puts "Input document isn't a well-formatted format string (scan for single '%' chars)"
            end
        end
        epilogue = format_epilogue()
        if epilogue
            doc.concat(epilogue)
        end
        doc
    end

    def write_doc(doc)
        $logger.warn "Save documentation to: #{@outfile}"
        File.open(@outfile, 'w') {|io| io.puts doc}
    end

    private
    def check_filetype(base)
        base = @insyntax if @insyntax
        @filetypes.keys.each do |ext|
            rv = check_this_filetype(base, ext, ext)
            return rv if rv
        end
        return :general
    end

    def check_this_filetype(base, ext, key)
        case ext
        when String, Symbol
            return key || ext if base == ext
        when Regexp
            return key || ext if base.instance_of?(String) and base =~ ext
        when Array
            ext.each do |e|
                rv = check_this_filetype(base, e, key)
                return rv if rv
            end
        else
            return nil
        end
    end

    def filename_on_disk(filename)
        if File.exist?(filename)
            return filename
        else
            if @repo
                return File.join(@repo, filename)
            end
            for root in @config['roots'] || []
                repo = File.join(root, File.basename(@outfile, '.*'))
                filename1 = File.join(repo, filename)
                if File.exist?(filename1)
                    @repo = repo
                    @outfile = File.join(repo, @outfile)
                    return filename1
                end
            end
            r = @config['replacements']
            if r and r[filename]
                return r[filename]
            else
                g = @config['gsub']
                if g
                    for rxs, rpl in g
                        filename = filename.gsub(Regexp.new(rxs), rpl)
                    end
                end
                return filename
            end
        end
    end

end


if __FILE__ == $0
    VimDedoc.new.parse_arguments(ARGV).process
end

