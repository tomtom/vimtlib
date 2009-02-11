#!/usr/bin/env ruby
# tbibtools.rb -- bibtex-related utilities
#   @Author:      Tom Link (micathom AT gmail com?subject=vim)
#   @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
#   @Created:     2007-03-28.
#   @Last Change: 2009-02-11.
#   @Revision:    0.6.750
#
# This file provides the class TBibTools that can be used to sort and 
# process bibtex files, list bibtex keys etc.
#
# Please be aware though that TBibTools#simple_bibtex_parser makes a few 
# assumptions about the bibtex file. So it's quite possible that it will 
# fail in some occasions. This is rather a quick hack than a real 
# parser.

require 'optparse'
require 'rbconfig'

class TBibTools

    # Some of this class's methods can be used in the configuration 
    # file. Please see the examples in the methods' documentation.
    #
    # New formatting options can be defined with the methods: shortcut 
    # and def_*.
    #
    # The formatting options (methods matching preprocess_*, head_*, body_*, 
    # tail_*, format_*, shortcut_*) are defined here, too.
    class Configuration
        attr_accessor :case_sensitive
        attr_accessor :entry_format
        attr_accessor :entry_format_default
        attr_accessor :sort
        attr_accessor :input_files
        attr_accessor :output_file
        attr_accessor :filter_rx
        attr_accessor :ignore_fields
        attr_accessor :list_format_string
        attr_accessor :strings_expansion
        attr_accessor :keys_order
        attr_accessor :stripPrelude
        attr_accessor :query_rx

        def initialize(tbibtools)
            @tbibtools            = tbibtools
            @case_sensitive       = true
            @stripPrelude         = false
            @entry_format         = []
            @entry_format_default = []
            @input_files          = []
            @output_file          = nil
            @query_rx             = {}
            @ignore_fields        = []
            @sort                 = '_id'
            @filter_rx            = nil
            @list_format_string   = '#{_id}'
            @strings_expansion    = false
            @keys_order           = [
                'author',
                'title',
                'editor',
                'booktitle',
                'journal',
                'publisher',
                'institution',
                'address',
                'howpublished',
                'organization',
                'school',
                'series',
                'type',
                'year',
                'month',
                'edition',
                'chapter',
                'doi',
                'volume',
                'number',
                'pages',
                'url',
                'eprint',
                'file',
                'crossref',
                'key',
                'keywords',
                'note',
                'annote',
                'abstract',
            ]
            fs = [File.join(Config::CONFIG['sysconfdir'], 'tbibtools.rb')]
            fs << File.join(ENV['USERPROFILE'], 'tbibtools.rb') if ENV['USERPROFILE']
            fs << File.join(ENV['HOME'], '.tbibtools') if ENV['HOME']
            fs.each {|f| config f}
        end

        # Attribute reader
        def entry_format
            (@entry_format.empty? ? @entry_format_default : @entry_format).uniq
        end

        # Usage in configuration file:
        #   config 'file.rb'
        def config(value)
            # require value if File.exists?(value)
            if File.exists?(value)
                fc = File.read(value)
                self.instance_eval(fc)
            end
        end

        # Usage in configuration file:
        #   sort_case true
        #   sort_case false
        def sort_case(value)
            @case_sensitive = value
        end

        # Usage in configuration file:
        #   sort_key '_id'
        def sort_key(value)
            @sort = value
        end

        # Usage in configuration file:
        #   input 'file1.bib', 'file2.bib'
        def input(*value)
            @input_files = @input_files | value
        end

        # Usage in configuration file:
        #   output 'file.bib'
        def output(value)
            @output_file = value
        end

        # Usage in configuration file:
        #   strip 'mynotes'
        def strip(*value)
            @ignore_fields += value
        end

        # Usage in configuration file:
        #   filter /Humpty Dumpty/
        def filter(value)
            @filter_rx = value
        end

        # Usage in configuration file:
        #   strip_prelude
        #   strip_prelude false
        def strip_prelude(value=true)
            @stripPrelude = value
        end

        # Usage in configuration file:
        #   format 'stripRedundantTitle', 'stripEmpty'
        def format(*value)
            set_format(@entry_format, *value)
        end

        # Usage in configuration file:
        #   default_format 'tml'
        def default_format(*value)
            set_format(@entry_format_default, *value)
        end

        # Usage in configuration file:
        #   list_format '#{_lineno}: #{author|editor|institution}: #{title|booktitle}'
        def list_format(value)
            @list_format_string = value
        end

        # Usage in configuration file:
        #   expand_strings false
        #   expand_strings true
        def expand_strings(value=false)
            @strings_expansion = value
        end

        # Usage in configuration file:
        #   order 'author', 'title', 'editor', 'booktitle'
        def order(*value)
            @keys_order = value
        end

        # Usage in configuration file:
        #   query FIELD1 => REGEXP1, FIELD2 => REGEXP2, ...
        def query(value)
            value.each do |field, rx|
                @query_rx[field] = rx
            end
        end

        def shortcut_tml(acc=nil)
            sort_case false
            f = [
              'nnIsYear',
              'sortCrossref',
              'downcaseType',
              'downcaseKey',
              'canonicPages',
              'squeeze',
              'languageLongNames',
              'canonicAuthors',
              'canonicKeywords',
              'canonicQuotes',
              'stripRedundantTitle',
              'stripEmpty',
              'bracket',
              'align',
              # 'unwrap',
              'indent',
            ]
            set_format acc, *f
            f
        end
        
        def shortcut_ls(acc=nil)
            f = ['list', 'stripPrelude']
            set_format acc, *f
            f
        end

        # Usage in configuration file:
        #   shortcut "NAME" => ["FORMAT1", "FORMAT2" ...]
        def shortcut(hash)
            for name, list in hash
                # {list.map{|a| a.inspect}.join(', ')}
                eval <<-EOR
                def shortcut_#{name}(acc=nil)
                    f = #{list.inspect}
                    set_format acc, *f
                    f
                end
                EOR
            end
        end

        # Usage in configuration file:
        #   def_preprocess("NAME") {|entry| BODY}
        # => entry
        def def_preprocess(name, &block)
            if block.arity != 1
                raise ArgumentError, "Wrong number of arguments for preprocess definition: #{name}"
            end
            self.class.send(:define_method, "preprocess_#{name}", &block)
        end

        # Usage in configuration file:
        #   def_head("NAME") {|entry, type| BODY}
        def def_head(name, &block)
            if block.arity != 2
                raise ArgumentError, "Wrong number of arguments for body definition: #{name}"
            end
            self.class.send(:define_method, "head_#{name}", &block)
        end

        # Usage in configuration file:
        #   def_body("NAME") {|entry, key, value| BODY}
        def def_body(name, &block)
            if block.arity != 3
                raise ArgumentError, "Wrong number of arguments for body definition: #{name}"
            end
            self.class.send(:define_method, "body_#{name}", &block)
        end

        # Usage in configuration file:
        #   def_tail("NAME") {|entry| BODY}
        def def_tail(name, &block)
            if block.arity != 1
                raise ArgumentError, "Wrong number of arguments for tail definition: #{name}"
            end
            self.class.send(:define_method, "tail_#{name}", &block)
        end

        # Usage in configuration file:
        #   def_format("NAME") {|args, entry, key, value| BODY}
        def def_format(name, &block)
            if block.arity != 4
                raise ArgumentError, "Wrong number of arguments for format definition: #{name}"
            end
            self.class.send(:define_method, "format_#{name}", &block)
        end

        # Usage in configuration file:
        #   duplicate_field("NAME") {|oldval, val| BODY}
        # => newval
        def duplicate_field(name, &block)
            if block.arity != 2
                raise ArgumentError, "Wrong number of arguments for duplicate_field definition: #{name}"
            end
            self.class.send(:define_method, "duplicate_field_#{name}", &block)
        end

        def is_crossreferenced(e)
            id = e['_id']
            @tbibtools.crossreferenced.include?(id)
        end

        def preprocess_selectCrossref(e)
            is_crossreferenced(e) ? e : nil
        end

        def preprocess_unselectCrossref(e)
            is_crossreferenced(e) ? nil : e
        end

        def head_list(e, type)
            @list_format_string.gsub(/#(#|((-?\d+)?)\{(.+?)\})/) do |s|
                if s == '##'
                    '#'
                else
                    width = $2
                    field = $4.split(/\|/).find {|f| e[f]}
                    e, k, v = format_unwrap('', e, field, e[field])
                    if !width.empty?
                        "%#{$2}s" % v
                    else
                        v
                    end
                end
            end
        end

        def head_downcaseType(e, type)
            type = type.downcase
            head_default(e, type)
        end

        def head_upcaseType(e, type)
            type = type.upcase
            head_default(e, type)
        end

        def head_default(e, type)
            "@#{type}{#{e['_id']},\n"
        end

        def body_default(e, k, v)
            "#{k} = #{v},\n"
        end

        def tail_default(e)
            "}\n\n"
        end

        def tail_list(e)
            "\n"
        end

        def format_list(args, e, k, v)
            return []
        end

        def format_nil(args, e, k, v)
            return [e, nil, v]
        end

        def format_check(args, e, k, v)
            # if v =~ /(^["#$%&~_^{}]|[^\\]["#$%&~_^{}])/
            # if v =~ /(^[#$&~_{}^%]|[^\\][#$&~_{}^%])/
            if v =~ /(^[#&%]|[^\\][#&%])/
                puts "Problematic entry #{e["_id"]}: #{k}=#{v}"
            end
            return [e, k, v]
        end

        def format_bracket(args, e, k, v)
            if v.empty? or v =~ /[^0-9]/
                # v = v.gsub(/([{}])/, '\\\\\\1')
                v = "{#{v}}"
            end
            return [e, k, v]
        end

        def format_quote(args, e, k, v)
            if v.empty? or v =~ /[^0-9]/
                # v = v.gsub(/([{}])/, '\\\\\\1')
                v = %{"#{v}"}
            end
            return [e, k, v]
        end

        def format_downcaseKey(args, e, k, v)
            return [e, k.downcase, v]
        end

        def format_upcaseKey(args, e, k, v)
            return [e, k.upcase, v]
        end

        def format_squeeze(args, e, k, v)
            return [e, k, v.gsub(/\s+/, ' ')]
        end

        def format_indent(args, e, k, v)
            if args.empty?
                i = '    '
            else
                i = ' ' * args.to_i
            end
            # v = " #{v.gsub(/(\n)/, '\\1' + i)}"
            v = v.gsub(/(\n)/, '\\1' + i)
            k = "#{i}#{k}"
            return [e, k, v]
        end

        def format_stripEmpty(args, e, k, v)
            if v.empty?
                return [e]
            end
            return [e, k, v]
        end

        def format_stripRedundantTitel(args, e, k, v)
            if k == 'title' && e['booktitle'] == v
                return [e]
            else
                return [e, k, v]
            end
        end

        def format_gsub(args, e, k, v)
            for rx, text in args.scan(/([^:]+):([^:]+)/)
                # v = v.gsub(Regexp.new(Regexp.escape(rx)), text.gsub(/[\\]/, '\\\\ \\\\\\0'))
                v = v.gsub(Regexp.new(Regexp.escape(rx)), text.gsub(/[\\]/, '\\\\\\0'))
            end
            return [e, k, v]
        end

        def format_align(args, e, k, v)
            k = ['%-', e['_keysmlen'], 's'].join % k
            return [e, k, v]
        end

        def format_canonicAuthors(args, e, k, v)
            if k == 'author' || k == 'editor'
                v = v.split(/\s+and\s+/)
                v.map! do |au|
                    if au =~ /^(\S+?),\s*(.+)$/
                        [$2, $1].join(' ')
                    else
                        au
                    end
                end
                v = v.join(' and ')
            end
            return [e, k, v]
        end

        def format_canonicPages(args, e, k, v)
            if k == 'pages'
                v.gsub!(/\s*[-–]+\s*/, '-')
            end
            return [e, k, v]
        end

        def format_canonicQuotes(args, e, k, v)
            if v =~ /"/
                v.gsub!(/(^|[^\\])("|')/) do |t|
                    pre  = $1
                    case $2
                    when '"'
                        qu = $1 =~ /[[:cntrl:][:punct:][:space:]]/ ? '``' : %{''}
                    else
                        qu = $1 =~ /[[:cntrl:][:punct:][:space:]]/ ? '`' : %{'}
                    end
                    [pre, qu].join
                end
            end
            return [e, k, v]
        end

        def format_canonicKeywords(args, e, k, v)
            if k =~ /^keyword/ and v !~ /;/ and v =~ /,/
                v.gsub!(/,\s+/, '; ')
            end
            return [e, k, v]
        end

        def format_languageShortNames(args, e, k, v)
            if k == 'language'
                case v.downcase
                when 'english', 'englisch'
                    v = 'en'
                when 'german', 'deutsch'
                    v = 'de'
                when 'francais', 'french'
                    v = 'fr'
                end
            end
            return [e, k, v]
        end

        def format_languageLongNames(args, e, k, v)
            if k == 'language'
                case v.downcase
                when 'en'
                    v = 'english'
                when 'de'
                    v = 'german'
                when 'fr'
                    v = 'francais'
                end
            end
            return [e, k, v]
        end

        def format_wrap(args, e, k, v)
            v = v.gsub(/(.{20,78}\s)/, "\\1\n  ")
            return [e, k, v]
        end

        def format_unwrap(args, e, k, v)
            v = v.gsub(/\s*\n\s*/, ' ') if v.is_a?(String)
            return [e, k, v]
        end

        # def format_<+TODO+>(args, e, k, v)
        #     <+TODO+>
        #     return [e, k, v]
        # end

        def duplicate_field_author(oldval, val)
            [oldval, val].join(' and ')
        end

        def duplicate_field_abstract(oldval, val)
            [oldval, val].join("\n")
        end

        def duplicate_field_url(oldval, val)
            [oldval, val].join(' ')
        end

        def duplicate_field_keywords(oldval, val)
            (oldval.split(/[;,]\s*/) | val.split(/[;,]\s*/)).join(', ')
        end

        private
        def set_format(acc, *value)
            acc ||= @entry_format
            value.map {|f| f.to_s}.each do |fmt|
                fmeth = %{shortcut_#{fmt}}
                if self.respond_to?(fmeth)
                    send(fmeth, acc)
                else
                    acc << fmt
                end
            end
        end
    end

    attr_accessor :configuration
    attr_accessor :crossreferenced

    def initialize
        @configuration   = TBibTools::Configuration.new(self)
        @crossreferenced = []
    end

    def process(args)
        parse_command_line_args(args)
        if !@configuration.input_files.empty?
            bib = @configuration.input_files.map {|f| File.read(f)}.join("\n")
        else
            bib = readlines.join
        end
        out = bibtex_sort_by(nil, bib)
        if @configuration.output_file
            File.open(@configuration.output_file, 'w') {|io| io.puts out}
        else
            puts out
        end
    end

    # Parse the command line args (provided as array), print a help 
    # message on -h, --help, or -?.
    def parse_command_line_args(args)
        opts = OptionParser.new do |opts|
            opts.banner =  'Usage: tbibtools [OPTIONS] [FILES] < IN > OUT'
            opts.separator ''
            opts.separator 'tbibtools is a free software with ABSOLUTELY NO WARRANTY under'
            opts.separator 'the terms of the GNU General Public License version 2 or newer.'
            opts.separator ''
        
            opts.on('-c', '--config=FILE', String, 'Configuration file') do |value|
                @configuration.config value
            end

            opts.on('-e', '--regexp=REGEXP', String, 'Display entries matching the regexp') do |value|
                @configuration.filter Regexp.new(value)
            end

            opts.on('-f', '--format=STRING', String, 'Re-format entries (order matters)') do |value|
                @configuration.format *value.split(/,/)
            end

            opts.on('--[no-]formatted', 'Unformatted output') do |bool|
                unless bool
                    @configuration.entry_format = []
                    @configuration.entry_format_default = []
                end
            end

            opts.on('-i', '--[no-]case-sensitive', 'Case insensitive') do |bool|
                @configuration.sort_case bool
            end
           
            opts.on('-l', '--format-list=[STRING]', String, 'Format string for list (implies --ls)') do |value|
                @configuration.shortcut_ls
                @configuration.list_format value if value
            end

            opts.on('--ls', 'Synonym for: -f list,stripPrelude ("list" implies "unwrap")') do |bool|
                @configuration.shortcut_ls if bool
            end

            opts.on('-o', '--output=FILE', String, 'Output file') do |value|
                @configuration.output value
            end

            opts.on('-P', '--strip-prelude', 'Strip the prelude: same as -f stripPrelude but helps to maintain the original formatting') do |bool|
                @configuration.strip_prelude
            end

            opts.on('-q', '--query=FIELD=REGEXP', String, 'Show entries for which field matches the regexp') do |value|
                field, rx = value.split(/=/, 2)
                @configuration.query field => Regexp.new(rx, Regexp::IGNORECASE)
            end

            opts.on('-s', '--sort=STRING', String, 'Sort (default: sort by key; key = _id, type = _type)') do |value|
                @configuration.sort_key value
            end

            opts.on('-S', '--[no-]expand-strings', 'Replace/expand strings') do |bool|
                @configuration.expand_strings bool
            end

            opts.on('--strip=FIELDS', String, 'Ignore/strip fields') do |value|
                @configuration.strip value.split(/,/)
            end

            opts.on('-u', '--unsorted', 'Unsorted output') do |bool|
                @configuration.sort_key nil
            end

            opts.separator ''
            opts.separator 'Other Options:'
        
            opts.on('--debug', Integer, 'Show debug messages') do |v|
                $DEBUG   = true
                $VERBOSE = true
            end
        
            opts.on('-v', '--verbose', 'Run verbosely') do |v|
                $VERBOSE = true
            end
        
            opts.on('-h', '--help', 'Show this message') do
                puts opts
                exit 1
            end

            opts.separator ''
            opts.separator 'Available formats:'
            format_rx = /^(format|preprocess|head|body|tail)_/
            format_names = (['nnIsYear', 'sortCrossref', 'downcaseType', 'upcaseType'] + 
                            @configuration.methods.find_all{|m| m =~ format_rx}.collect{|m| m.sub(format_rx, '')}).uniq.sort.join(', ')
            opts.separator format_names

            opts.separator ''
            opts.separator 'Known format shortcuts:'
            acc = []
            @configuration.methods.find_all{|m| m =~ /^shortcut_/}.sort.each do |meth|
                fn  = meth.sub(/^shortcut_/, '')
                fs  = @configuration.send(meth, acc)
                opts.separator "#{fn}: #{fs.join(',')}"
            end
        end
        @configuration.input *opts.parse!(args)
        self
    end

    # Parse text and sort by field. If field is nil, use @sort. 
    # Return the result as string.
    def bibtex_sort_by(field, text)
        field ||= @configuration.sort
        entries, prelude = simple_bibtex_parser(text, @configuration.strings_expansion)
        if @configuration.filter_rx
            entries.delete_if do |key, value|
                value['_entry'] !~ @configuration.filter_rx
            end
        end
        unless @configuration.query_rx.empty?
            entries.delete_if do |key, value|
                @configuration.query_rx.all? do |field, rx|
                    value[field] !~ rx
                end
            end
        end
        unless @configuration.ignore_fields.empty?
            entries.each do |key, value|
                ignore_fields.each do |field|
                    value.delete(field)
                end
            end
        end
        acc = []
        unless @configuration.stripPrelude or @configuration.entry_format.include?('stripPrelude')
            acc << prelude
        end
        keys = entries.keys
        # if @configuration.entry_format.include?('sortCrossref')
        #     @crossreferenced = keys.map {|k| entries[k]['crossref']}.compact
        # end
        if field
            keys.sort! do |a,b|
                aa = entries[a][field] || ''
                bb = entries[b][field] || ''
                unless @configuration.case_sensitive
                    aa = aa.downcase
                    bb = bb.downcase
                end
                if @configuration.entry_format.include?('nnIsYear')
                    aa = replace_yy(aa)
                    bb = replace_yy(bb)
                end
                if @configuration.entry_format.include?('sortCrossref') and 
                    ((ac = @crossreferenced.include?(a)) or (bc = @crossreferenced.include?(b)))
                    if ac and bc
                    elsif ac
                        aa = 1
                        bb = 0
                    elsif bc
                        aa = 0
                        bb = 1
                    end
                end
                aa <=> bb
            end
        end
        for i in keys
            e = entries[i]
            if @configuration.entry_format.empty?
                ee = e['_entry']
            else
                ee = format(e)
            end
            acc << ee if ee
        end
        if @configuration.entry_format.include?('nil')
            ''
        else
            acc.join 
        end
    end

    # Format the entry on the basis of @configuration.entry_format.
    #
    # The output is constructed from
    #
    #   [
    #       head_FORMAT(entry, type)
    #       format_FORMAT(args, entry, key, val) -> body_FORMAT(entry, key, val)
    #       tail_FORMAT(entry)
    #   ].join("\n")
    #
    # In order to define your own formats, please see 
    # TBibTools::Configuration.
    def format(e)
        keys = e.keys.find_all {|k| k[0..0] != '_'}
        keys.sort! do |a,b|
            (@configuration.keys_order.index(a.downcase) || 99999) <=> (@configuration.keys_order.index(b.downcase) || 99999)
        end
        acc = []
        # e['_keysmlen'] = keys.inject(0) {|m, k| [m, k.size].max} + 1
        e['_keysmlen'] = keys.inject(0) {|m, k| [m, k.size].max}
        for_methods('preprocess') do |meth|
            e = @configuration.send(meth, e)
        end
        return e unless e
        unless @configuration.entry_format.include?('nil')
            type = e['_type']
            for_methods('head') do |meth|
                v = @configuration.send(meth, e, type)
                acc << v if v
            end
        end
        catch(:next_entry) do
            for k in keys
                v = e[k]
                catch(:next_key) do
                    for f in @configuration.entry_format
                        if f =~ /^(\w+)=(.*)$/
                            f = $1
                            a = $2
                        else
                            a = ''
                        end
                        m = "format_#{f}"
                        if @configuration.respond_to?(m)
                            e, k, v = @configuration.send(m, a, e, k, v)
                            if e.nil?
                                # throw :next_entry
                                throw :next_entry
                            elsif k.nil?
                                throw :next_key
                           end
                        end
                    end
                    for_methods('body') do |meth|
                        v = @configuration.send(meth, e, k, v)
                        acc << v if v
                    end
                end
            end
        end
        unless @configuration.entry_format.include?('nil')
            for_methods('tail') do |meth|
                v = @configuration.send(meth, e)
                acc << v if v
            end
        end
        # return acc.join("\n")
        return acc
    end

    def for_methods(prefix, &block)
        rv = @configuration.entry_format.map {|m| [prefix, m].join('_')}
        rv = rv.find_all {|m| @configuration.respond_to?(m)}
        if rv.empty?
            md = [prefix, 'default'].join('_')
            if @configuration.respond_to?(md)
                rv << md
            end
        end
        rv.each {|meth| block.call(meth)}
    end

    # Taken from deplate (http://deplate.sf.net). 
    # Return a hash (key=filename) of parsed bibtex files (as hashes).
    def simple_bibtex_reader(bibfiles)
        acc = {}
        for b in bibfiles
            b = File.expand_path(b)
            unless File.exist?(b)
                b = Deplate::External.kpsewhich(self, b)
                if b.empty?
                    next
                end
            end
            File.open(b) {|io| acc[b] = simple_bibtex_parser(io.readlines, @configuration.strings_expansion)}
        end
        acc
    end

    # Taken from deplate (http://deplate.sf.net). Parse text and 
    # return a hash of hashes. Create the pseudo-keys _type, _id, 
    # and _entry.
    #
    # This method works with a few simple regexps and makes a few 
    # assumptions about your bib file:
    #
    # * @string definitions should be collected in the prelude, i.e. 
    #   before any bib entry.
    # * @string definitions must be oneliners.
    # * The bib entries must be more or less valid.
    # * Entries with curly braces may confuse the "parser".
    #
    # Return an array: [entries as hash, prelude as string]
    def simple_bibtex_parser(text, strings_expansion=true)
        prelude = []
        strings = {}
        entries = {}
        lineno  = 1
        # m = /^\s*(@(\w+)\{(.*?)\})\s*(?=(^@|\z))/m.match(text)
        while (m = /^\s*(@(\w+)\{(.*?))\s*(?=(^@|\z))/m.match(text))
            text  = m.post_match
            body  = m[0]
            type  = m[2]
            inner = m[3]
            case type.downcase
            when 'string'
                prelude << body
                mi = /^\s*(\S+?)\s*=\s*(.+?)\s*\}?\s*$/m.match(inner)
                r = mi[2]
                if r =~ /^(".*?"|'.*?'|\{.*?\})$/
                    r = r[1..-2]
                end
                strings[mi[1]] = r
            else
                mi = /^\s*(\S+?)\s*,(.*)$/m.match(inner)
                id = mi[1]
                e  = mi[2]
                # arr = e.scan(/^\s*(\w+)\s*=\s*(\{.*?\}|\d+)\s*[,}]\s*$/m)
                arr = e.scan(/^\s*([[:alnum:]-]+)\s*=\s*(\{.*?\}|".*?"|\d+)\s*[,}]\s*$/m)
                entry = {}
                arr.each do |var, val, rest|
                    # EXPERIMENTAL: something like author={{Top Institute}} didn't work. I'm not sure though if this is able to deal with the last field in a bibtex entry correctly
                    # n = /^\s*\{(.*?)\}\s*($|\}\s*\z)/m.match(val)
                    if (n = /^\s*\{(.*?)\}\s*$/m.match(val))
                        val = n[1]
                    elsif (n = /^\s*"(.*?)"\s*$/m.match(val))
                        val = n[1]
                    end
                    if strings_expansion and strings[val]
                        val = strings[val]
                    end
                    if (oldval = entry[var])
                        if oldval != val
                            meth = "duplicate_field_#{var}"
                            if @configuration.respond_to?(meth)
                                val = @configuration.send(meth, oldval, val)
                                $stderr.puts "Resolve duplicate fields with mismatching values: #{id}.#{var}" if $VERBOSE
                                $stderr.puts "=> #{val.inspect}" if $DEBUG
                            else
                                $stderr.puts "Can't resolve duplicate fields with mismatching values: #{id}.#{var}"
                                $stderr.puts "#{oldval.inspect} != #{val.inspect}" if $DEBUG
                            end
                        end
                    end
                    entry[var] = val
                    case var
                    when 'crossref'
                        @crossreferenced << val
                    end
                end
                entry['_lineno'] = lineno.to_s
                entry['_type']   = type
                entry['_id']     = id
                entry['_entry']  = body
                if entries[id]
                    if entries[id] != entry
                        $stderr.puts "Duplicate key, mismatching entries: #{id}"
                        if $DEBUG
                            $stderr.puts entries[id]['_entry'].chomp
                            $stderr.puts '<=>'
                            $stderr.puts entry['_entry'].chomp
                            $stderr.puts
                        end
                    end
                    entries[id].update(entry)
                else
                    entries[id] = entry
                end
            end
            lineno += (m.pre_match.scan(/\n/).size + body.scan(/\n/).size)
        end
        if text =~ /\S/
            $stderr.puts "Trash in bibtex input: #{text}" if $VERBOSE
        end
        return entries, prelude.join
    end

    private
    def replace_yy(text)
        text.gsub(/(^|\D)(\d)(\d)(\D|$)/) do |r|
            [
                $1, 
                $2.to_i > Time.now.strftime('%y')[0..0].to_i ? '19' : '20',
                $2, $3, $4
            ].join
        end
    end

end

if __FILE__ == $0
    TBibTools.new.process(ARGV)
end

