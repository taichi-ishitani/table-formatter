#!/usr/bin/env ruby

# file: table-formatter.rb

class TableFormatter

  attr_accessor :source, :labels, :border, :divider
  
  def initialize(source: nil, labels: nil, border: true, wrap: true, divider: nil)    

    super()
    @source = source
    @labels = labels
    @border = border
    @wrap = wrap
    @divider = divider
    @maxwidth = 60
    
  end
  
  def display(width=nil, widths: nil, markdown: false)
    
    return display_markdown(@source, @labels) if markdown

    if @labels then

      @align_cols, labels = [], []

      @labels.each do |raw_label|

        col_just, label = just(raw_label)
        @align_cols << col_just
        labels << label
      end

    end

    #width ||= @maxwidth
    @width = width
    @maxwidth = width if width
    a = @source.map {|x| x.map{|y| y.length > 0 ? y : ' ' }}.to_a

    column_widths = widths ? widths : fetch_column_widths(a)

    column_widths[-1] -= column_widths.inject(&:+) - width if width

    records = format_rows(a, column_widths)

    div =  (border == true ? '-' : '') * records[0].length + "\n"
    label_buffer = ''
    
    label_buffer = format_cols(labels, column_widths) + "\n" + div if labels

    div + label_buffer + records.join("\n") + "\n" + div

  end

  alias to_s display


  private

  def display_markdown(a, fields)
    
    print_row = -> (row, widths) do
      '| ' + row.map\
          .with_index {|y,i| y.to_s.ljust(widths[i])}.join(' | ') + " |\n"
    end

    print_thline = -> (row, widths) do
      '|:' + row.map\
          .with_index {|y,i| y.to_s.ljust(widths[i])}.join('|:') + "|\n"
    end

    print_rows = -> (rows, widths) do
      rows.map {|x| print_row.call(x,widths)}.join
    end

    widths = ([fields] + a).transpose.map{|x| x.max_by(&:length).length}
    th = '|' + fields.join('|') + "|\n"
    th = print_row.call(fields, widths)
    th_line = print_thline.call widths.map {|x| '-' * (x+1)}, widths

    tb = print_rows.call(a, widths)
    table = th + th_line + tb
  end
  
  def fetch_column_widths(a)

    d = tabulate(a).map &:flatten

    # find the maximum lengths
    d.map{|x| x.max_by(&:length).length}
  end
  
  def format_cols(row, col_widths, bar='')
    
    outer_bar, inner_spacer = '', ''
    (outer_bar = bar = '|'; inner_spacer = ' ') if border == true
    col_spacer = @divider ? 0 : 2
    
    buffer = outer_bar

    
    row.each_with_index do |col, i|

      align = @align_cols ? @align_cols[i] : :ljust

      val, next_bar =  if (i < row.length - 1 || border) then
        [col.method(align).call(col_widths[i] + col_spacer), bar]
      else
        [col.method(align).call(col_widths[i] + col_spacer).rstrip, '']
      end

      buffer += inner_spacer + val + next_bar.to_s
    end    
    
    buffer

  end  

  def format_rows(raw_a, col_widths)

    @width = col_widths.inject(&:+)

    col_widths[-1] -= col_widths.inject(&:+) - @maxwidth if @width > @maxwidth
   
    a = if @wrap == true then
    
      raw_a.map do |raw_row|

        rowx = raw_row.map.with_index do |col, i|
          col.chars.each_slice(col_widths[i]).map(&:join)
        end    
        
        max_len = rowx.max_by {|x| x.length}.length
        
        rowx.each do |x| 
          len = x.length
          x.concat ([''] * (max_len - len)) if len < max_len
        end
        
        rowx.transpose
      end.flatten(1)
    else
      raw_a
    end
    
    a.map {|row| format_cols(row, col_widths, divider) }

  end

  def just(x)

    case x
      when /^:.*:$/
        [:center, x[1..-2]]
      when /:$/
        [:rjust, x[0..-2]]
      when /^:/
        [:ljust, x[1..-1]]
      else
        [:ljust, x]
    end
  end

  def tabulate(a)
    a[0].zip(a.length > 2 ? tabulate(a[1..-1]) : a[-1])
  end

end