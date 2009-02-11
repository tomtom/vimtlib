# tVimTools.rb
#   @Author:      Tom Link (micathom AT gmail com?subject=vim)
#   @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
#   @Created:     2007-03-28.
#   @Last Change: 2009-02-11.
#   @Revision:    0.59

class TVimTools
    def initialize(buffer=nil)
        set_buffer(buffer)
    end

    def set_buffer(buffer=nil)
        @buffer = buffer || VIM::Buffer.current
    end

    def buffer_get_range(from, to)
        # p "DBG buffer_get_range #{from} #{to}"
        (from..to).collect {|l| @buffer[l]}.join("\n")
    end

    def buffer_delete_range(from, to)
        # p "DBG buffer_delete_range #{from} #{to}"
        from.upto(to) do |i|
            @buffer.delete(from)
        end
    end

    def buffer_append_text(line, text)
        # p "DBG buffer_append_text #{line}"
        for l in text.split(/\n/, -1).reverse
            # l = l.gsub(/\\/, '\\\\\\\\')
            @buffer.append(line, l)
        end
    end

    def buffer_replace_range(from, to, text)
        # p "DBG buffer_replace_range #{from} #{to}"
        buffer_delete_range(from, to)
        buffer_append_text(from - 1, text)
    end

    def with_range(from, to, &block)
        # p "DBG process_range #{from} #{to}"
        text = buffer_get_range(from, to)
        return block.call(text)
    end

    def process_range(from, to, &block)
        buffer_replace_range(from, to, with_range(from, to, &block))
    end
end

