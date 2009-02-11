#!/usr/bin/env ruby
# vimball.rb
# @Author:      Tom Link (micathom AT gmail com)
# @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
# @Created:     2009-02-10.
# @Last Change: 2009-02-11.
#
# This script creates and installs vimballs without vim.
#
# Before actually using this script, you might want to run
#
#   vimball.rb --print-config
#
# and check the values. If they don't seem right, you can change them in 
# the configuration file (in YAML format).
#
# Known incompatibilities:
# - Vim's vimball silently converts windows line end markers to unix 
# markers. This script won't -- unless you run it with Windows's ruby 
# maybe.
#
# TODO:
# - copy (copy the files)
# - link (symlink the files)
# - zip (create a zip archive, not a vba)
# - list files in a vimball
# - uninstall (or add info of installed vbas to .VimballRecord)
#


require 'yaml'
require 'logger'
require 'optparse'
require 'pathname'
require 'zlib'


class Vimball

    APPNAME = 'vimball'
    VERSION = '1.0.112'

    class AppLog
        def initialize(output=$stdout)
            @output = output
            $logger = Logger.new(output)
            $logger.progname = APPNAME
            $logger.datetime_format = "%H:%M:%S"
            set_level
        end
    
        def set_level
            if $DEBUG
                $logger.level = Logger::DEBUG
            elsif $VERBOSE
                $logger.level = Logger::WARN
            else
                $logger.level = Logger::INFO
            end
        end
    end


    HEADER = <<HEADER
" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
HEADER


    def initialize(args)

        AppLog.new

        @opts = Hash.new

        @opts['vimfiles'] = catch(:ok) do
            throw :ok, ENV['VIMFILES'] if ENV['VIMFILES']
            ['.vim', 'vimfiles'].each do |dir|
                ['HOME', 'USERPROFILE', 'VIM'].each do |env|
                    pdir = ENV[env]
                    if pdir
                        vimfiles = File.join(pdir, dir)
                        throw :ok, vimfiles if File.directory?(vimfiles)
                    end
                end
            end
            '.'
        end

        @opts['configfile'] = File.join(@opts['vimfiles'], 'vimballs', 'config.yml')
        @configs = []
        read_config
        
        @opts['compress'] ||= false
        @opts['helptags'] ||= %{vim -T dumb --cmd "helptags %s|quit"}
        @opts['outdir']   ||= File.join(@opts['vimfiles'], 'vimballs')

        @dry = false

        opts = OptionParser.new do |opts|
            opts.banner =  'Usage: vimball.rb [OPTIONS] COMMAND FILES ...'
            opts.separator ' '
            opts.separator 'vimball.rb is a free software with ABSOLUTELY NO WARRANTY under'
            opts.separator 'the terms of the GNU General Public License version 2 or newer.'
            opts.separator ' '
            opts.separator 'Commands:'
            opts.separator '   vba     ... Create a vimball'
            opts.separator '   install ... Install a vimball'
            opts.separator ' '
        
            opts.on('-b', '--vimfiles DIR', String, 'Vimfiles directory') do |value|
                @opts['vimfiles'] = value
            end

            opts.on('-c', '--config YAML', String, 'Config file') do |value|
                @opts['configfile'] = value
                read_config
            end

            opts.on('-d', '--dir DIR', String, 'Destination directory for vimballs') do |value|
                @opts['outdir'] = value
            end

            opts.on('-n', '--dry-run', 'Don\'t actually run any commands; just print them') do |bool|
                @dry = bool
            end

            opts.on('--print-config', 'Print the configuration and exit') do |bool|
                puts YAML.dump(@opts)
                exit
            end

            opts.on('-z', '--gzip', 'Save as vba.gz') do |value|
                @opts['compress'] = value
            end


            opts.separator ' '
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

            opts.on('--version', 'Version number') do |bool|
                puts VERSION
                exit 1
            end
        
            opts.on_tail('-h', '--help', 'Show this message') do
                puts opts
                exit 1
            end
        end
        $logger.debug "command-line arguments: #{args}"

        @opts['files'] ||= []
        rest = opts.parse!(args)
        @opts['cmd'] = rest.shift
        @opts['files'].concat(rest)

    end


    def run
        if ready?

            meth = "do_#{@opts['cmd']}"
            @opts['files'].each do |file|
                $logger.info "#{@opts['cmd']}: #{file}"
                if respond_to?(meth)
                    send(meth, file)
                else
                    $logger.fatal "Unknown command: #{@opts['cmd']}"
                    exit 5
                end
            end

            post = "post_#{@opts['cmd']}"
            send(post) if respond_to?(post)

        end
    end


    protected


    def ready?

        unless @opts['vimfiles'] and File.directory?(@opts['vimfiles'])
            $logger.fatal "Where are your vimfiles?"
            exit 5
        end

        cmds = ['vba', 'install']
        unless cmds.include?(@opts['cmd'])
            $logger.fatal "Command must be one of: #{cmds.join(', ')}"
            exit 5
        end

        # unless @opts['configfile']
        #     puts "Where is my config file?"
        #     return false
        # end

        if @opts['files'].empty?
            $logger.fatal "No input files"
            exit 5
        end

        return true

    end


    def read_config
        file = @opts['configfile']
        until @configs.include?(file)
            @configs << file
            if File.readable?(file)
                $logger.info "Read configuration from #{file}"
                @opts.merge!(YAML.load_file(file))
                file = @opts['configfile']
                break
            end
        end
    end


    def do_vba(recipe)
        
        vimball = [HEADER]

        files = File.readlines(recipe)
        files.each do |file|
            file = file.strip
            unless file.empty?
                filename = File.join(@opts['vimfiles'], file)
                if File.readable?(filename)
                    content = File.readlines(filename)
                else
                    $logger.fatal "Cannot read file: #{filename}"
                    exit 5
                end
                # content.each do |line|
                #     line.sub!(/(\r\n|\r)$/, "\n")
                # end

                filename = Pathname.new(filename).relative_path_from(Pathname.new(@opts['vimfiles'])).to_s
                filename.gsub!(/\\/, '/')

                rewrite = @opts['rewrite']
                if rewrite
                    rewrite.each do |(pattern, replacement)|
                        rx = Regexp.new(pattern)
                        filename.gsub!(rx, replacement)
                    end
                end

                vimball << "#{filename}	[[[1\n#{content.size}\n"
                vimball.concat(content)
            end
        end

        vbafile = File.join(@opts['outdir'], File.basename(recipe, '.recipe') + '.vba')
        ensure_dir_exists(File.dirname(vbafile))
        vimball = vimball.join

        if @opts['compress']
            vbafile += '.gz'
            $logger.info "Save as: #{vbafile}"
            unless @dry
                Zlib::GzipWriter.open(vbafile) do |gz|
                    gz.write(vimball)
                end
            end
        else
            $logger.info "Save as: #{vbafile}"
            unless @dry
                File.open(vbafile, 'w') do |io|
                    io.puts(vimball)
                end
            end
        end

    end


    def do_install(file)

        vimball = nil
        if file =~ /\.gz$/
            File.open(file) do |f|
                gzip = Zlib::GzipReader.new(f)
                vimball = gzip.readlines
            end
        else
            vimball = File.readlines(file)
        end

        header = vimball.shift(3).join
        if header != HEADER
            $logger.fatal "Not a vimball: #{file}"
            exit 5
        end

        $logger.info "Install #{file}"

        until vimball.empty?

            fileheader = vimball.shift
            nlines = vimball.shift.to_i
            m = /^(.*?)\t\[\[\[1$/.match(fileheader)
            if m and nlines > 0
                filename = File.join(@opts['outdir'], m[1])
                content = vimball.shift(nlines)

                ensure_dir_exists(File.dirname(filename))

                $logger.info "Write #{filename}"
                unless @dry
                    File.open(filename, 'w') do |io|
                        io.puts(content.join)
                    end
                end

            else
                $logger.fatal "Error when parsing vimball: #{file}"
                exit 5
            end

        end

    end


    def post_install
        helptags = @opts['helptags']
        if helptags
            helptags = helptags % File.join(@opts['outdir'], 'doc')
            $logger.info "Create helptags: #{helptags}"
            `#{helptags}`
        end
    end


    def ensure_dir_exists(dir)
        unless @dry or File.exist?(dir) or dir.empty? or dir == '.'
            parent = File.dirname(dir)
            unless File.exist?(parent)
                ensure_dir_exists(parent)
            end
            $logger.info "mkdir #{dir}"
            Dir.mkdir(dir)
        end
    end

end


if __FILE__ == $0

    Vimball.new(ARGV).run

end


# Local Variables:
# revisionRx: VERSION\s\+=\s\+\'
# End:
