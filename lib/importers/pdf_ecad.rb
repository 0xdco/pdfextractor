class Importers::PdfEcad
  CATEGORIES = {"C" => "Author", "CA" => "Author", "E" => "Publisher", "V" => "Versionist", "SE" => "SubPublisher"}

  def initialize(str_file_path)
    @pdf_reader = PDF::Reader.new(str_file_path)
  end

  # Returns the work Hash, with right holders
  # Iterate through each line looking for Works && Right Holders
  def works
    work_list = []
    last_work = nil
    lines.each do |line|
      is_work = work(line)
      if is_work
        work_list << last_work if last_work
        last_work = is_work
      elsif right_holder(line)
        last_work[:right_holders] << right_holder(line)
      else
        next
      end
    end
    # Remains one, always!
    # I know I know, this aint beautiful but Just Works (TM)
    work_list << last_work if last_work
    work_list
  end

  def work(line)
    values = /^(\d*)\s*([A-Z]\-\d{3}\.\d{3}\.\d{3}\-\d|\-\s*\.\s*\.\s*\-)\s*(.*)(LB|BL|DU|HO|DP|DE|CO|EC)\s*(\d{2}\/\d{2}\/\d{4}){0,1}$/.match(line)
    return nil if values.nil?
    created_at = values[5].nil? ? "" : values[5]
    {iswc: values[2],
     title: values[3].strip,
     external_ids: [{source_name: "Ecad", source_id: values[1]}],
     situation: values[4],
     created_at: created_at,
     right_holders: []
    }
  end


  # 40
  # 106535       MADALENA PETZL                                                                           CA 20,00                       4
  # 400
  # 39873        MARCOS PRADO DE OLIVEIRA            MARCOS PRADO                         SICAM           CA 33,34                       3
  def right_holder_less_info(line)
    values = /^(\d*)\s*(\w.*)\s*(CA|C|E|V|SE)\s*(\d{1,3}\,\d{0,2}|\d{1,3}\,\d{0,2}\d*\/\d*\/\d*)\s*(\d*)$/.match(line)
    return nil if values.nil?

    stripped_names = values[2].strip
    multi_names = stripped_names.split(/\s{2,3}/).reject(&:blank?)
    case multi_names.size
    when 3
      # Nome, Pseudo, Sociedade
      name = multi_names[0].strip
      pseudos = [
        {name:multi_names[1].strip, main: true}
      ]
      sociedade = multi_names[2]
    when 2
      # Nome, Pseudo
      name = multi_names[0]
      pseudos = [
        {name:multi_names[1].strip, main: true}
      ]
      sociedade = ""
    when 1
      name = multi_names[0]
      pseudos = []
      sociedade = ""
    end

    ipi = nil
    {external_ids: [{source_name: 'Ecad', source_id: values[1]}],
     name: name,
     pseudos: pseudos,
     ipi: ipi,
     share: fix_share(values[4]),
     society_name: sociedade,
     role: CATEGORIES[values[3]]
    }
  end

  def right_holder(line)
    right_holder_more_info(line) || right_holder_less_info(line)
  end

  def right_holder_more_info(line)
    values = /^(\d*)([A-Z ].*)(\s\d*\.\d*\.\d*\.\d*)(.*)(CA|C|E|V|SE)\s*(\d{1,3}\,\d{0,2}|\d{1,3}\,\d{0,2}\d*\/\d*\/\d*)\s*(\d*)$/.match(line)
    return nil if values.nil?

    share = fix_share(values[6])

    stripped_names = values[2].strip
    multi_names = /(.*)\s{2,3}(.*)/.match(stripped_names)
    if multi_names
      name = multi_names[1].strip
      pseudos = [
        {name:multi_names[2].strip, main: true}
      ]
    else
      name = stripped_names
      # pseudos = [{name: stripped_names, main: true}]
      pseudos = []
    end

    ipi = values[3].strip.split('.').join

    {external_ids: [{source_name: 'Ecad', source_id: values[1]}],
     name: name,
     pseudos: pseudos,
     ipi: ipi,
     share: share,
     society_name: values[4].strip,
     role: CATEGORIES[values[5]]
    }
  end

  # Used to aid on test, we know the test doc has 241 right holders
  # on total, so just to certify
  def holders
    lines.map{|l| right_holder(l) }.compact
  end

  def lines
    @pdf_reader.pages.flat_map do |p|
      join_orphan_ids(p.text.split("\n")).reject{|l| l.blank?}
    end
  end

  private
  def fix_share(field)
    if field.match(/\//)
      share_date = /^(.*)(\d{2}\/\d{2}\/\d{2})/.match(field)
      share = '%.2f' % share_date[1].gsub(/,/, '.').to_f
    else
      share = '%.2f' % field.gsub(/,/, '.').to_f
    end
    share = share.to_f
  end

  # I had some trouble with some lines that would split the ID
  # and the rest of the line in two lines. The following code
  # will join them
  def join_orphan_ids(elines)
    i = 0
    while i < elines.size do
      if elines[i] && elines[i].match(/^\d*$/)
        elines[i] = elines[i] + elines[i+1]
        elines[i+1] = nil
      end
      i += 1
    end
    elines
  end
end
