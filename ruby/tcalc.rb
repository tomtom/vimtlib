#!/usr/bin/env ruby
# tcalc.rb
# @Last Change: 2010-03-13.
# Author::      Tom Link (micathom AT gmail com)
# License::     GPL (see http://www.gnu.org/licenses/gpl.txt)
# Created::     2007-10-23.
#
# TODO:
# - reimplement the whole stuff in java or maybe d? ... or whatever
# - call this interpreter "whatever" :)


require 'matrix'
require 'mathn'
require 'optparse'
# require 'pp'
require 'continuation' if RUBY_VERSION >= '1.9.0'

module TCalc
    CONFIG_DIR = ENV['TCALC_HOME'] || File.join(ENV['HOME'], '.tcalc')

    module_function
    def lib_filename(filename)
        File.join(CONFIG_DIR, filename) if File.directory?(CONFIG_DIR)
    end
end


class TCalc::Base
    FLOAT_PERIOD = (1.1).to_s[1..1]
    attr_accessor :eval_and_exit

    def initialize(&block)
        @cmds = [
            'ls',
            'yank', 'y',
            'define', 'let', 'rm', 'unlet',
            'hex', 'HEX', 'oct', 'bin', 'dec', 'print', 'inspect', 'float', 'format',
            'dup', 'd',
            'copy', 'c',
            'pop', 'p', '.',
            'del', 'delete',
            'rot', 'r',
            'swap', 's',
            'stack_empty?', 'stack_size',
            'iqueue_empty?', 'iqueue_size',
            'Array', 'group', 'g',
            'ungroup', 'u',
            'Sequence', 'seq',
            'map', 'mmap', 'any?', 'all?',
            'array_push', 'array_pop', 'array_unshift', 'array_shift', 'array_empty?',
            'plot',
            'if', 'ifelse',
            'recapture', 'do',
            'clear',
            'debug',
            'begin', 'end',
            'Rational', 'Complex', 'Integer', 'Matrix',
            'at',
            'args', 'assert', 'validate',
            'source', 'require',
            'history',
            'p',
            # 'puts', 'pp',
            '#',
            '!=', 'and', 'or',
        ]
        @ymarks = ['+', '*', 'x', '.', '#', ':', '~', '^', '@', '$', 'o', '"']
        reset_words true
        reset
        @format  = '%p'
        @word_rx = '[[:alpha:]_]+'
        @debug         = $DEBUG
        @debug_breaks  = []
        @debug_status  = 'step'
        @buffer        = ''
        @history       = []
        @history_size  = 30
        @eval_and_exit = false
        @numclasses    = [Float, Complex, Rational, Integer, Matrix, Vector]
        setup
        instance_eval &block if block
    end


    def setup
        iqueue_reset initial_iqueue
    end



    def tokenize(string)
        string.scan(/("(\\"|[^"])*?"|\S+)+/).map {|a,b| a}
    end


    # spaghetti code ahead.
    def repl(initial=[])
        (iqueue).concat(initial) unless initial.empty?
        loop do
            if iqueue_empty?
                if @eval_and_exit
                    dump_stack
                    return
                else
                    display_stack
                    cmdi = read_buffered_input
                    break if quit?(cmdi)
                    @history.unshift(cmdi)
                    @history[@history_size..-1] = nil if @history.size > @history_size
                    iqueue_reset tokenize(cmdi)
                end
            end
            while !iqueue_empty?
                begin
                    cmd = iqueue_shift
                    # puts cmd if @debug
                    if !cmd.kind_of?(String)
                        stack_push cmd

                    elsif cmd == '(' or cmd == '(('
                        body  = []
                        case cmd
                        when '(('
                            depth = 1
                            args_to_be_set = true
                            body << 'begin' << '('
                        else
                            depth = 0
                            args_to_be_set = false
                        end
                        while !iqueue_empty?
                            elt = iqueue_shift
                            case elt
                            when '(('
                                depth += 2
                                body << elt
                            when '('
                                depth += 1
                                body << elt
                            when ')'
                                if depth == 0
                                    if cmd == '(('
                                        body << 'end'
                                    end
                                    break
                                else
                                    if depth == 1 and args_to_be_set
                                        args_to_be_set = false
                                        if body.last == '('
                                            body.pop
                                        else
                                            body << ')' << 'args'
                                        end
                                    else
                                        body << ')'
                                    end
                                    depth -= 1
                                end
                            else
                                body << elt
                            end
                        end
                        if depth == 0
                            stack_push body
                        else
                            echo_error 'Unmatched ('
                        end

                    elsif cmd == '['
                        stack_push '['

                    elsif cmd == ']'
                        start = stack.rindex('[')
                        if start
                            arr = stack_get(start + 1 .. -1)
                            stack_set start .. -1, nil
                            stack_push arr
                        else
                            echo_error 'Unmatched ]'
                        end

                    elsif cmd =~ /^-?\d/
                        stack_push eval(cmd).to_f

                    elsif cmd =~ /^"(.*)"$/
                        stack_push eval(cmd)

                    elsif cmd =~ /^'(.*)$/
                        stack_push $1

                    elsif cmd =~ /^#(\d+)?$/
                        n = 1 + ($1 || 1).to_i
                        val = (stack).delete_at(-n)
                        stack_push val if val

                    elsif cmd =~ /^(#@word_rx)=$/
                        set_word($1, stack_pop)

                    # elsif cmd =~ /^:(\(.+?\))?(#@word_rx)$/
                    elsif cmd =~ /^:(#@word_rx)$/
                        idx = iqueue.index(';')
                        def_lambda($1, iqueue_get(0 .. idx - 1))
                        iqueue_set 0 .. idx, nil

                    elsif cmd == '->'
                        set_word iqueue_shift, stack_pop

                    elsif cmd == '/*'
                        idx = iqueue.index('*/')
                        iqueue_set 0 .. idx, nil

                    else
                        if @debug and (@debug_status == 'step' or
                                       (@debug_status == 'run' and @debug_breaks.any? {|b| cmd =~ b}))
                            loop do
                                dbgcmd = read_input('DEBUG (%s): ' % cmd)
                                case dbgcmd
                                when 's', 'step'
                                    @debug_status = 'step'

                                when 'r', 'run'
                                    @debug_status = 'run'

                                when 'b', 'break'
                                    bp = read_input('DEBUG Breakpoints (REGEXPs): ')
                                    bp.split(/\s+/).map do |b|
                                        @debug_breaks << Regexp.new(b)
                                    end

                                when 'B', 'unbreak'
                                    @debug_breaks = []

                                when 'ii', 'iqueue'
                                    print_array([iqueue.join(' ')])
                                    press_enter

                                when 'is', 'stack'
                                    print_array(stack)
                                    press_enter

                                when 'ls'
                                    list_words

                                when 'h', 'help'
                                    print_array([
                                                 's,  step   ... Step mode',
                                                 'r,  run    ... Run (until breakpoint is reached)',
                                                 'b,  break  ... Define breakpoints',
                                                 'B,  unbreak... Reset breakpoints',
                                                 'ii, iqueue ... Inspect input queue',
                                                 'is, stack  ... Inspect input queue',
                                                 'ls         ... List words',
                                                 'h,  help   ... Help',
                                                 'n, c, <CR> ... Continue',
                                            ], false, false)
                                    press_enter

                                when 'n', 'c'
                                    break

                                else
                                    break
                                end
                            end
                        end

                        cmdm = /^(#?[^@#,[:digit:]]*)(#|\d+)?(@(\d+))?(,(.+))?$/.match(cmd)
                        cmd_name   = cmdm[1]
                        cmd_count  = cmdm[2]
                        cmd_arrity = cmdm[4] ? cmdm[4].to_i : nil
                        cmd_ext    = cmdm[6]

                        if cmd_name =~ /^#(#@word_rx)$/
                            cmd_name = '#'
                            cmdw = $1
                        else
                            cmdw = nil
                        end

                        case cmd_count
                        when '#'
                            cmd_count = stack_pop.to_i

                        when nil, ''
                            cmd_count = 1

                        else
                            cmd_count = cmd_count.to_i
                        end

                        # p "DBG", cmd_name, cmd_count, cmd_ext
                        cmd_count.times do
                            if words.has_key?(cmd_name)
                                # p "DBG t2"
                                # p "DBG word"
                                if cmd_name =~ /^__.*?__$/
                                    iqueue_unshift(get_word(cmd_name).dup)
                                else
                                    iqueue_unshift(*get_word(cmd_name))
                                end

                            elsif @cmds.include?(cmd_name)
                                # p "DBG t1"
                                case cmd_name

                                when 'history'
                                    print_array(@history, false, false)
                                    n = read_input('Select entry: ')
                                    if n =~ /^\d+$/
                                        # iqueue_unshift(*tokenize(@history[n.to_i]))
                                        @buffer = @history[n.to_i]
                                    end

                                when 'source'
                                    filename = stack_pop
                                    if check_this(String, filename, cmd, cmd_name)
                                        unless File.exist?(filename)
                                            filename = lib_filename(filename)
                                        end
                                        if filename and File.exist?(filename)
                                            contents = File.read(filename)
                                            iqueue_unshift(*tokenize(contents))
                                        else
                                            echo_error 'source: File does not exist'
                                        end
                                    end
                                    break

                                when 'require'
                                    fname = stack_get(-1)
                                    require stack_pop if check_this(String, fname, [fname, cmd], cmd_name)
                                    #
                                # when 'puts'
                                #     puts stack_pop
                                #     press_enter

                                when 'p'
                                    p stack_pop
                                    press_enter

                                # when 'pp'
                                #     pp stack_pop
                                #     press_enter

                                when 'debug'
                                    @debug = cmd_count.to_i != 0
                                    if @debug
                                        @debug_status = cmd_ext || 'step'
                                    end

                                when 'assert'
                                    assertion = stack_pop
                                    unless check_assertion(assertion, [assertion, cmd])
                                        iqueue_reset
                                        break
                                    end

                                when 'args'
                                    assertion = stack_pop
                                    ok, names = descriptive_assertion(assertion, [assertion, cmd])
                                    names.compact.each do |name|
                                        # p "DBG", name
                                        set_word(name, stack_pop)
                                    end
                                    unless ok
                                        iqueue_reset
                                        break
                                    end

                                when 'validate'
                                    assertion = stack_pop
                                    stack_push check_assertion(assertion, [assertion, cmd], true)
                                    break

                                when 'ls'
                                    list_words

                                when 'yank', 'y'
                                    args = format(stack_get(-cmd_count .. -1))
                                    args = args.join("\n")
                                    export(cmd_ext, args)
                                    break

                                when 'define'
                                    name = stack_pop
                                    body = stack_pop
                                    def_lambda(name, body)

                                when 'let'
                                    set_word(cmd_ext, stack_pop)

                                when 'unlet', 'rm'
                                    case cmd_ext
                                    when '*'
                                        reset_words
                                    else
                                        words.delete(cmd_ext)
                                    end

                                when 'begin'
                                    scope_begin

                                when 'end'
                                    scope_end

                                when 'hex'
                                    @format = '%x'

                                when 'HEX'
                                    @format = '%X'

                                when 'oct'
                                    @format = '%o'

                                when 'bin'
                                    @format = '%016b'

                                when 'dec'
                                    @format = '%d'

                                when 'print', 'inspect'
                                    @format = '%p'

                                when 'float'
                                    @format = '%f'

                                when 'format'
                                    @format = cmd_ext

                                when 'copy', 'c'
                                    stack_push stack_get(-cmd_count - 1)
                                    break

                                when 'dup', 'd'
                                    stack_push stack_get(-1) unless stack_empty?

                                when 'del', 'delete'
                                    (stack).delete_at(-cmd_count - 1)
                                    break

                                when 'stack_empty?'
                                    stack_push stack_empty?
                                    break

                                when 'stack_size'
                                    stack_push stack.size
                                    break

                                when 'iqueue_empty?'
                                    stack_push iqueue_empty?
                                    break

                                when 'iqueue_size'
                                    stack_push iqueue.size
                                    break

                                when 'pop', 'p', '.'
                                    stack_pop

                                when 'rot', 'r'
                                    n = cmd_count + 1
                                    (stack).insert(-n, stack_pop)
                                    break

                                when 'swap', 's'
                                    n = cmd_count + 1
                                    val = stack_get(-n .. -1).reverse
                                    stack_set -n .. -1, val
                                    break

                                when 'g', 'group', 'Array'
                                    acc  = []
                                    rows = cmd_count
                                    rows.times {acc << stack_pop}
                                    stack_push acc.reverse
                                    break

                                when 'u', 'ungroup'
                                    # iqueue_unshift(*stack_pop)
                                    (stack).concat(stack_pop)

                                when 'recapture', 'do'
                                    block = stack_pop
                                    cmd_count.times {iqueue_unshift(*block)} if check_this(Array, block, [block, cmd], cmd_name)
                                    break

                                when 'clear'
                                    stack_reset
                                    break

                                when 'if'
                                    test, ifblock = stack_get(-2..-1)
                                    stack_set -2..-1, nil
                                    if test
                                        iqueue_unshift(*ifblock)
                                    end

                                when 'ifelse'
                                    test, ifblock, elseblock = stack_get(-3..-1)
                                    stack_set -3..-1, nil
                                    if test
                                        iqueue_unshift(*ifblock)
                                    else
                                        iqueue_unshift(*elseblock)
                                    end

                                when 'at'
                                    index = stack_pop
                                    item  = stack_pop
                                    case index
                                    when Array
                                        stack_push item[*index]
                                    else
                                        stack_push item[index]
                                    end

                                when 'map'
                                    fun  = stack_pop
                                    seq  = stack_pop
                                    iseq = seq.map do |xval|
                                        [xval, fun, '#1,<<']
                                    end
                                    stack_push []
                                    iqueue_unshift *(iseq.flatten)

                                when 'mmap'
                                    fun  = stack_pop
                                    seq  = stack_pop
                                    iseq = seq.map do |xval|
                                        ['[', xval, xval, fun, ']', '#1,<<']
                                    end
                                    stack_push []
                                    iqueue_unshift *(iseq.flatten)

                                when 'any?'
                                    fun  = stack_pop
                                    seq  = stack_pop
                                    check_this(Array, fun, [seq, fun, cmd], cmd_name)
                                    check_this(Array, seq, [seq, fun, cmd], cmd_name)
                                    iseq = [false]
                                    while !seq.empty?
                                        iseq.unshift(*[seq.pop, fun, '(', true, ')', '('].flatten)
                                        iseq.push(')', 'ifelse')
                                    end
                                    iqueue_unshift *(iseq.flatten)

                                when 'all?'
                                    fun  = stack_pop
                                    seq  = stack_pop
                                    check_this(Array, fun, [seq, fun, cmd], cmd_name)
                                    check_this(Array, seq, [seq, fun, cmd], cmd_name)
                                    iseq = [true]
                                    seq.each do |elt|
                                        iseq.unshift(*[elt, fun, '(', ].flatten)
                                        iseq.push(')', '(', false, ')', 'ifelse')
                                    end
                                    iqueue_unshift *(iseq.flatten)

                                when 'array_push'
                                    val = stack_pop
                                    arr = stack_get(-1)
                                    check_this(Array, arr, [arr, val, cmd], cmd_name)
                                    arr << val

                                when 'array_pop'
                                    arr = stack_get(-1)
                                    check_this(Array, arr, [arr, val, cmd], cmd_name)
                                    stack_push arr.pop

                                when 'array_unshift'
                                    val = stack_pop
                                    arr = stack_get(-1)
                                    check_this(Array, arr, [arr, val, cmd], cmd_name)
                                    arr.unshift(val)

                                when 'array_shift'
                                    arr = stack_get(-1)
                                    check_this(Array, arr, [arr, val, cmd], cmd_name)
                                    stack_push arr.shift

                                when 'array_empty?'
                                    arr = stack_get(-1)
                                    check_this(Array, arr, [arr, val, cmd], cmd_name)
                                    stack_push arr.empty?

                                when 'plot'
                                    xdim = stack_pop
                                    ydim = stack_pop
                                    vals = stack_pop
                                    plot(ydim, xdim, vals, cmd_ext)

                                when 'seq', 'Sequence'
                                    step = stack_pop
                                    top  = stack_pop
                                    idx  = stack_pop
                                    acc  = []
                                    while idx <= top
                                        acc << idx
                                        idx += step
                                    end
                                    stack_push acc

                                when 'Integer'
                                    stack_push stack_pop.to_i

                                when 'Rational'
                                    denominator = stack_pop
                                    numerator   = stack_pop
                                    stack_push Rational(numerator.to_i, denominator.to_i)

                                when 'Complex'
                                    imaginary = stack_pop
                                    real      = stack_pop
                                    if check_this(Numeric, imaginary, [imaginary, real, cmd], cmd_name) and check_this(Numeric, real, [imaginary, real, cmd], cmd_name)
                                        stack_push Complex(real, imaginary)
                                    end

                                when 'Matrix'
                                    mat = stack_get(-1)
                                    if check_this(Array, mat, [mat, cmd], cmd_name)
                                        stack_push Matrix[ *stack_pop ]
                                    end

                                when '!='
                                    stack_push (stack_pop != stack_pop)

                                when 'and'
                                    val1 = stack_pop
                                    val2 = stack_pop
                                    stack_push (val1 && val2)

                                when 'or'
                                    val1 = stack_pop
                                    val2 = stack_pop
                                    stack_push (val1 || val2)

                                when '#'
                                    if cmdw
                                        item = get_word(cmdw)
                                    else
                                        item = (stack).delete_at(-1 - cmd_count)
                                    end
                                    argn = cmd_arrity || item.method(cmd_ext).arity
                                    args = get_args(1, argn)
                                    val  = item.send(cmd_ext, *args)
                                    stack_push val
                                end

                            else
                                # p "DBG t4"
                                if RUBY_VERSION >= '1.9.0'
                                    cmd_method = cmd_name.intern
                                else
                                    cmd_method = cmd_name
                                end
                                catch(:continue) do
                                    @numclasses.each do |c|
                                        if c.instance_methods.include?(cmd_method)
                                            # p "DBG #{c}"
                                            argn = cmd_arrity || c.instance_method(cmd_method).arity
                                            args = get_args(0, argn)
                                            # p "DBG", cmd_method, argn, args
                                            val = [args[0].send(cmd_method, *args[1 .. -1])].flatten
                                            # p "DBG", val
                                            (stack).concat(val)
                                            throw :continue
                                        end
                                    end

                                    [Math, *@numclasses].each do |c|
                                        if c.constants.include?(cmd_method)
                                            # p "DBG #{c} constant"
                                             stack_push c.const_get(cmd_method)
                                             throw :continue
                                        end
                                    end

                                    [Math, *@numclasses].each do |c|
                                        if c.methods.include?(cmd_method)
                                            # p "DBG t3", cmd_method
                                            # p "DBG math"
                                            argn = cmd_arrity || c.method(cmd_method).arity
                                            args = get_args(1, argn)
                                            (stack).concat([c.send(cmd_method, *args)].flatten)
                                            throw :continue
                                        end
                                    end

                                    completion = complete_command(cmd_name, cmd_count, cmd_ext)
                                    if completion
                                        iqueue_unshift(completion)
                                    else
                                        echo_error "Unknown or ambiguous command: #{cmd_name}"
                                    end

                                end
                            end
                        end
                    end

                rescue Exception => e
                    if @debug
                        print_array([
                            '%s: %s' % [e.class, e.to_s], 
                            '__IQUEUE__',
                            iqueue.join(' '),
                            '__STACK__',
                            stack,
                            '__BACKTRACE__',
                            e.backtrace[0..5]].flatten, true, false)
                        press_enter
                        # raise e
                    elsif @eval_and_exit
                        echo_error '%s: %s' % [e.class, e.to_s]
                        exit 5
                    else
                        echo_error e.to_s.inspect
                    end

                end
            end
        end
        cleanup
    end


    def quit?(input)
        input.nil? || input =~ /^(bye|exit|quit|)$/
    end


    def cleanup
        puts 'Bye!'
    end


    def reset
        stack_reset
        iqueue_reset
        self
    end


    def reset_words(initial=false)
        new = {'__WORDS__' => nil}
        unless initial
            old = words
            words.each do |k, v|
                if k =~ /^__.*?__$/
                    new[k] = v
                end
            end
        end
        @words_stack = [new]
    end


    def list_words
        wd = words
        ls = wd.keys.sort.map do |key|
            next if key =~ /^_/
                val = wd[key]
            case val
            when Array
                val = val.join(' ')
            else
                val = val.inspect
            end
            "#{key}: #{val}"
        end
        print_array(ls.compact, true, false)
        press_enter
    end


    def words
        @words_stack[0]
    end


    def get_word(word)
        case word
        when '__WORDS__'
            rv = words.dup
            rv.delete_if {|k,v| k =~ /^__.*?__$/}
            [ rv ]
        else
            (words)[word]
        end
    end


    def set_word(word, value)
        # p "DBG set_word", word, value, words
        case word
        when '__WORDS__'
            w = value.dup
            @words_stack[0].each {|k,v| w[k] = v if k =~ /^__.*?__$/}
            @words_stack[0] = w
        else
            (words)[word] = value
        end
    end


    def def_lambda(word, body)
        word_def = ['begin', *body] << 'end'
        set_word(word, word_def)
    end


    def stack
        get_word '__STACK__'
    end


    def stack_reset(val=[])
        set_word '__STACK__', val
    end


    def stack_get(pos)
        (stack)[pos]
    end


    def stack_set(pos, arg)
        (stack)[pos] = arg
    end


    def stack_push(*args)
        (stack).push(*args)
    end


    def stack_pop
        (stack).pop
    end


    def stack_empty?
        (stack).empty?
    end


    def iqueue
        get_word '__IQUEUE__'
    end


    def iqueue_reset(val=[])
        set_word '__IQUEUE__', val
    end


    def iqueue_get(pos)
        (iqueue)[pos]
    end


    def iqueue_set(pos, arg)
        (iqueue)[pos] = arg
    end


    def iqueue_unshift(*args)
        (iqueue).unshift(*args)
    end


    def iqueue_shift
        (iqueue).shift
    end


    def iqueue_empty?
        (iqueue).empty?
    end


    # This is probably the most expensive way to do this. Also, for 
    # objects like Array, Hash, this is likely to yield unexpected 
    # results.
    # This needs to be changed. For the moment it has to suffice though.
    def scope_begin
        @words_stack.unshift(words.dup)
    end


    def scope_end
        if @words_stack.size > 1
            @words_stack.shift
        else
            echo_error 'Scope error: end without begin'
        end
    end


    def plot(ydim, xdim, yvals, register)
        yyvals = yvals.map {|x,y| y}
        ymax   = yyvals.max
        ymin   = yyvals.min
        yrange = ymax - ymin
        xmin   = 0
        xmax   = 0
        xmarks = [nil] * xdim
        yscale = (ydim - 1) / yrange
        xscale = (xdim - 1) / (yvals.size - 1)
        canvas = Array.new(ydim) { ' ' * xdim }

        yvals.each_with_index do |xy, i|
            xpos = [[0, (i * xscale).round].max, xdim - 1].min
            xval, *yvals = xy
            if xval < xmin
                xmin = xval
            elsif xval > xmax
                xmax = xval
            end
            xmarks[xpos] = xval
            ylast = yvals.size - 1
            yvals.reverse.each_with_index do |y, yi|
                ypos = [ydim - 1, [0.0, (y - ymin) * yscale].max].min.round
                if yi == ylast
                    mark = xval.to_s.split(/[,.]/, 2)
                    mark = mark[1][0..0]
                else
                    mark = @ymarks[yi % @ymarks.size]
                end
                canvas[ypos][xpos] = mark
            end
        end

        ydiml = [ymin.round.to_s.size, ymax.round.to_s.size].max + 4
        ydim.to_i.times do |i|
            canvas[i].insert(0, "% #{ydiml}.2f: " % (ymin + i / yscale))
        end

        # canvas.unshift ''
        # xdiml = [('%.1f' % xmin).size, ('%.1f' % xmax).size].max
        xdiml = [xmin.to_i.abs.to_s.size, xmax.to_i.abs.to_s.size].max
        xlast = nil
        (0..xdiml).each do |i|
            row  = ' ' * xdim 
            (xdim.to_i).times do |j|
                xval0 = xmarks[j]
                if xval0
                    xvalt = xval0.truncate.abs
                    xsig  = xval0 >= 0 ? '+' : '-'
                    xval  = "#{xsig}%#{xdiml}d" % xvalt
                else
                    xval  = xlast
                end
                xch = xval[i..i]
                if j == 0 or j == xdim - 1
                    row[j] = xch
                elsif xsig == '+' and xlast != xval
                    row[j] = xch
                elsif xsig == '-' and xlast == xval and j > 2 and xvalt != 0
                    row[j - 1] = ' '
                    row[j] = xch
                end
                xlast = xval
            end
            canvas.unshift(' ' * (ydiml - 3) + '.    ' + row)
        end

        case register
        when nil, ''
            print_array(canvas, false, false)
            press_enter
        else
            export(register, canvas.reverse.join("\n"))
        end
    end


    def display_stack
        puts
        puts '--------------------------------'
        dstack = format(stack)
        idx  = dstack.size
        idxl = (idx - 1).to_s.size
        dstack.map! do |line|
            idx -= 1
            "%#{idxl}d: %s" % [idx, line]
        end
        puts dstack.join("\n")
    end


    def dump_stack
        dstack = format(stack)
        puts dstack.join(' ')
    end


    def read_buffered_input(*args)
        rv = read_input
        @buffer = ''
        return rv
    end


    def read_input(prompt='> ')
        print prompt
        STDIN.gets
    end


    def lib_filename(filename)
        TCalc.lib_filename(filename)
    end


    def initial_iqueue
        init = lib_filename('init.tca')
        if init and File.readable?(init)
            tokenize(File.read(init))
        else
            []
        end
    end


    def export(register, args)
        echo_error 'Export not supported'
    end


    def get_args(from, to)
        args = []
        for i in from..to
            args << stack_pop unless stack_empty?
        end
        args.reverse
    end


    def format(elt, level=1)
        case elt
        when Array
            elt = elt.map {|e| format(e, level + 1)}
            if level > 1
                '[%s]' % elt.join(', ')
            else
                beg = 0
                while elt[beg].nil? and beg < elt.size
                    beg += 1
                end
                elt[beg..-1]
            end
        when nil
            nil
        else
            sprintf(@format, elt)
        end
    end


    def check_assertion(assertion, cmd, quiet=false)
        ok, names = descriptive_assertion(assertion, cmd, quiet)
        return ok
    end


    def descriptive_assertion(assertion, cmd, quiet=false)
        names = []
        case assertion
        when Array
            ok = true
            assertion.reverse.each_with_index do |a, i|
                item = stack_get(-1 - i)
                ok1, name = check_item(a, item, cmd)
                names << name
                if ok and !ok1
                    ok = ok1
                end
            end
        else
            ok, name = check_item(assertion, (stack).last, cmd, quiet)
            names << name if name
        end
        return [ok, names]
    end


    def check_item(expected, observed, cmd, quiet=false)
        name = nil
        case expected
        when String
            if expected =~ /^(\w+):(.*)$/
                name = $1
                expected = $2
            end
            o = eval(expected)
        else
            o = expected
        end
        return [o ? check_this(o, observed, cmd, nil, quiet) : true, name]
    end


    def check_this(expected, observed, cmd, prefix=nil, quiet=false)
        case expected
        when Class
            ok = observed.kind_of?(expected)
        else
            ok = observed == expected
        end
        unless quiet
            unless ok
                echo_error "#{prefix || 'validate'}: Expected #{expected.to_s}, got #{observed.inspect}: #{cmd.inspect}"
            end
        end
        return ok
    end


    def print_array(arr, reversed=true, align=true)
        idxl = (arr.size - 1).to_s.size
        if reversed
            idx = -1
            arr.each do |e|
                idx += 1
                puts "%#{idxl}d: %s" % [idx, e]
            end
        else
            idx = arr.size
            arr.reverse.each do |e|
                idx -= 1
                puts "%#{idxl}d: %s" % [idx, e]
            end
        end
    end

    
    def press_enter
        puts '-- Press ANY KEY --'
        STDIN.getc
    end


    def echo_error(msg)
        puts msg
        sleep 1
    end


    def complete_command(cmd_name, cmd_count, cmd_ext, return_many = false)
        eligible = completion(cmd_name, return_many)
        if eligible.size == 1
            return eligible[0]
        elsif return_many
            return eligible
        else
            return nil
        end
    end


    def completion(alt, return_many = false)
        alx = Regexp.new("^#{Regexp.escape(alt)}.*")
        ids = @numclasses.map {|klass| klass.instance_methods | klass.constants}
        ids += Numeric.constants | Numeric.instance_methods | Math.methods | Math.constants | words.keys | @cmds
        ids.flatten!
        ids.uniq!
        ids = catch(:exit) do
            if return_many
                ids.map! {|a| a.to_s}
            else
                ids.map! do |a|
                    as = a.to_s
                    throw :exit, [as] if as == alt
                    as
                end
            end
            ids.sort! {|a,b| a <=> b}
            ids.delete_if {|e| e !~ alx}
            ids
        end 
        ids
    end
end



class TCalc::VIM < TCalc::Base
    @tcalc = nil

    class << self
        def get_tcalc
            unless @tcalc
                @tcalc = self.new
            end
            @tcalc
        end

        def reset
            get_tcalc.reset.setup
        end

        def repl(initial_args)
            tcalc = get_tcalc
            args  = tcalc.tokenize(initial_args)
            tcalc.repl(args)
        end

        def evaluate(initial_args)
            tcalc = get_tcalc
            tcalc.eval_and_exit = true
            begin
                repl(initial_args)
            ensure
                tcalc.eval_and_exit = false
            end
        end

        def completion(alt)
            @tcalc.completion(alt)
        end
    end


    def setup
        iqueue_reset (initial_iqueue + tokenize(VIM::evaluate("g:tcalc_initialize")))
    end


    def quit?(input)
        input.empty? or input == "\n"
    end


    def cleanup
    end


    def display_stack
        dstack = format(stack).join("\n")
        # VIM::evaluate(%{s:DisplayStack(split(#{dstack.inspect}, '\n'))})
        VIM::evaluate(%{s:DisplayStack(#{dstack.inspect})})
    end


    def dump_stack
        dstack = format(stack)
        VIM::command(%{let @" = #{dstack.join(' ').inspect}})
    end


    def print_array(arr, reversed=true, align=true)
        lines = arr.join("\n")
        rev   = reversed ? 1 : 0
        align = align ? 1 : 0
        VIM::evaluate(%{s:PrintArray(#{lines.inspect}, #{rev}, #{align})})
        # VIM::command("echo | redraw")
        # super
    end


    def read_input(prompt='> ')
        VIM::evaluate("input(#{prompt.inspect}, #{@buffer.inspect}, 'customlist,tcalc#Complete')")
    end


    def lib_filename(filename)
        File.join(VIM::evaluate('g:tcalc_dir'), filename)
    end


    def export(register, args)
        VIM::command("let @#{register || '*'} = #{args.inspect}")
    end


    def press_enter
        VIM::command("echohl MoreMsg")
        VIM::command("echo '-- Press ANY KEY --'")
        VIM::command("echohl NONE")
        VIM::evaluate("getchar()")
        VIM::command("echo")
    end


    def echo_error(msg)
        VIM::command("echohl error")
        VIM::command("echom #{msg.inspect}")
        VIM::command("echohl NONE")
        VIM::command("sleep 1")
        # press_enter
    end

end


class TCalc::CommandLine < TCalc::Base
    @@readline = false

    class << self
        def use_readline(val)
            @@readline = val
        end
    end


    def setup
        trap('INT') do
            cleanup
            exit 1
        end

        history = lib_filename('history.txt')
        if history and File.readable?(history)
            @history = eval(File.read(history))
        end

        if @@readline
            Readline.completion_proc = proc do |string|
                completion(string)
            end
            def read_input(prompt='> ')
                Readline.readline(prompt, true)
            end
        end

        super
    end


    def cleanup
        super
        history = lib_filename('history.txt')
        if history
            File.open(history, 'w') do |io|
                io.puts @history.inspect
            end
        end
    end


    def press_enter
        # puts '--8<-----------------'
    end

end


class TCalc::Curses < TCalc::CommandLine
    class << self
        def use_readline(val)
            puts 'Input via readline is not yet supported for the curses frontend.'
            puts 'Patches are welcome.'
            exit 5
        end
    end


    def setup
        super
        require 'curses'
        @curses = Curses
        @curses.init_screen
        @curses.cbreak
        @curses.noecho
        if (@has_colors = @curses.has_colors?)
            @curses.start_color
            @curses.init_pair(1, @curses::COLOR_YELLOW, @curses::COLOR_RED);
        end
    end


    def cleanup
        @curses.close_screen
        super
    end


    def display_stack
        @curses.clear
        dstack = format(stack)
        print_array(dstack)
    end


    def print_array(arr, reversed=true, align=true)
        @curses.clear
        y0   = curses_lines - 3
        x0   = 3 + @curses.cols / 3
        arr  = arr.reverse if reversed
        idxs = (arr.size - 1).to_s.size
        idxf = "%0#{idxs}d:"
        xlim = @curses.cols - idxs
        xlin = xlim - x0
        arr.each_with_index do |e, i|
            @curses.setpos(y0 - i, 0)
            @curses.addstr(idxf % i)
            if align
                period = e.rindex(FLOAT_PERIOD) || e.size
                @curses.setpos(y0 - i, x0 - period)
                @curses.addstr(e[0..xlin])
            else
                @curses.setpos(y0 - i, idxs + 2)
                @curses.addstr(e[0..xlim])
            end
        end
        @curses.setpos(y0 + 1, 0)
        @curses.addstr('-' * @curses.cols)
        @curses.refresh
    end


    def read_input(prompt='> ', index=0, string=@buffer)
        # @curses.setpos(@curses::lines - 1, 0)
        # @curses.addstr('> ' + string)
        # @curses.getstr
        histidx = -1
        curcol0 = prompt.size
        curcol  = string.size
        redraw_stack = false
        acc = []
        consume_char = nil
        debug_key = false
        loop do
            @curses.setpos(@curses::lines - 1, 0)
            @curses.addstr(prompt + string + ' ' * (@curses.cols - curcol - curcol0))
            @curses.setpos(@curses::lines - 1, curcol + curcol0)
            char = callcc do |cont|
                consume_char = cont
                @curses.getch
            end
            if redraw_stack
                display_stack
                redraw_stack = false
            end
            case char
            when 27
                acc = [27]
            when @curses::KEY_EOL, 10
                return string
            when @curses::KEY_BACKSPACE, 8, 127
                if curcol > 0
                    string[curcol - 1 .. curcol - 1] = ''
                    curcol -= 1
                end
            when @curses::KEY_CTRL_D, 4
                if curcol < string.size
                    string[curcol .. curcol] = ''
                end
            when @curses::KEY_CTRL_K, 11
                string[curcol..-1] = ''
                curcol = string.size
            when @curses::KEY_CTRL_W
                i = curcol
                while i > 0
                    i -= 1
                    if string[i..i] == ' '
                        break
                    end
                end
                string[i..curcol] = ''
                curcol = i
            when @curses::KEY_UP
                if histidx < (@history.size - 1)
                    histidx += 1
                    string = @history[histidx].dup
                    curcol = string.size
                end
            when @curses::KEY_DOWN
                if histidx > 0
                    histidx -= 1
                    string = @history[histidx].dup
                else
                    histidx = -1
                    string = ''
                end
                curcol = string.size
            when @curses::KEY_RIGHT
                curcol += 1 if curcol < string.size
            when @curses::KEY_LEFT
                curcol -= 1 if curcol > 0
            when @curses::KEY_CTRL_E, @curses::KEY_END
                curcol = string.size
            when @curses::KEY_CTRL_A, @curses::KEY_HOME
                curcol = 0
            when @curses::KEY_CTRL_I, 9
                s = string[0..curcol - 1]
                m = /\S+$/.match(s)
                if m
                    c0 = m[0]
                    cc = complete_command(c0, nil, nil, true)
                    p "DBG", cc
                    case cc
                    when Array
                        print_array(cc.sort)
                        redraw_stack = true
                    when String
                        string = [s, cc[c0.size .. -1], string[curcol .. - 1]].join
                        curcol += cc.size - c0.size
                    else
                        echo_error('No completion: %s' % c0, 0.5)
                    end
                end
            else
                if acc.empty?
                    string.insert(curcol, '%c' % char)
                    curcol += 1
                elsif char
                    acc << Curses.keyname(char)
                    case acc
                    when [27, '[', 'A']
                        acc = []
                        consume_char.call @curses::KEY_UP
                    when [27, '[', 'B']
                        acc = []
                        consume_char.call @curses::KEY_DOWN
                    when [27, '[', 'C']
                        acc = []
                        consume_char.call @curses::KEY_RIGHT
                    when [27, '[', 'D']
                        acc = []
                        consume_char.call @curses::KEY_LEFT
                    when [27, '[', '7', '~']
                        acc = []
                        consume_char.call @curses::KEY_HOME
                    when [27, '[', '8', '~']
                        acc = []
                        consume_char.call @curses::KEY_END
                    when [27, '[', '1', '1', '~']
                        acc = []
                        string += ' ls'
                        consume_char.call @curses::KEY_EOL
                    when [27, '[', '2', '0', '~']
                        acc = []
                        debug_key = !debug_key
                    when [27, '[', '3', '~']
                        acc = []
                        consume_char.call @curses::KEY_CTRL_D
                    when [27, 'O', 'a'] # ctrl-up
                        acc = []
                    when [27, 'O', 'b'] # ctrl-down
                        acc = []
                    when [27, 'O', 'c'] # ctrl-right
                        acc = []
                        while curcol < string.size
                            if string[curcol..curcol] == ' '
                                break
                            end
                            curcol += 1
                        end
                    when [27, 'O', 'd'] # ctrl-left
                        acc = []
                        while curcol > 0
                            if string[curcol..curcol] == ' '
                                break
                            end
                            curcol -= 1
                        end
                    when [27, '[', '3', '^'] # ctrl-del
                        acc = []
                    when [27, '[', '5', '~'] # page-up
                        acc = []
                    when [27, '[', '6', '~'] # page-down
                        acc = []
                    else
                        if debug_key
                            string += acc.inspect
                            curcol = string.size
                        end
                    end
                end
            end
        end
    end


    def press_enter
        msg = '-- Press ANY KEY --'
        # @curses.setpos(@curses::lines - 1, @curses::cols - msg.size)
        @curses.setpos(@curses::lines - 1, 0)
        @curses.addstr(msg)
        @curses.getch
    end


    def echo_error(msg, secs=1)
        @curses.setpos(@curses::lines - 1, 0)
        if @has_colors
            @curses.attron(@curses.color_pair(1));
            @curses.attron(@curses::A_BOLD);
        end
        @curses.addstr(msg)
        if @has_colors
            @curses.attroff(@curses::A_BOLD);
            @curses.attroff(@curses.color_pair(1));
        end
        @curses.refresh
        sleep secs
    end

    def curses_lines
        @curses.lines
    end

end



if __FILE__ == $0
    $tcalculator = TCalc::Curses
    eval_and_exit  = false

    cfg = TCalc.lib_filename('config.rb')
    if cfg and File.readable?(cfg)
        load cfg
    end

    opts = OptionParser.new do |opts|
        opts.banner =  'Usage: tcalc [OPTIONS] [INITIAL INPUT]'
        opts.separator ''
        opts.separator 'tcalc is a free software with ABSOLUTELY NO WARRANTY under'
        opts.separator 'the terms of the GNU General Public License version 2 or newer.'
        opts.separator ''

        opts.separator 'General Options:'
        opts.on('-e', '--[no-]eval', 'Eval arguments and return (implies --no-curses)') do |bool|
            eval_and_exit = bool
            $tcalculator = TCalc::Base
        end

        opts.on('--[no-]curses', 'Use curses gui') do |bool|
            if bool
                $tcalculator = TCalc::Curses
            else
                $tcalculator = TCalc::CommandLine
            end
        end

        opts.on('--[no-]readline', 'Use readline') do |bool|
            if bool
                require 'readline'
            end
            $tcalculator.use_readline bool
        end

        opts.separator ''
        opts.separator 'Other Options:'

        opts.on('--debug', 'Show debug messages') do |v|
            $DEBUG   = true
            $VERBOSE = true
        end

        opts.on('-v', '--verbose', 'Run verbosely') do |v|
            $VERBOSE = true
        end

        opts.on_tail('-h', '--help', 'Show this message') do
            puts opts
            exit 1
        end
    end

    iqueue = opts.parse!(ARGV)
    tcalc = $tcalculator.new do
        @eval_and_exit = eval_and_exit
    end
    tcalc.repl(iqueue)
end


# Local Variables:
# revisionRx: REVISION\s\+=\s\+\'
# End:
