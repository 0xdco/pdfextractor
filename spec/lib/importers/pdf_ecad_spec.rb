require 'spec_helper'

describe "Ecad PDF Import" do
  before(:each) do
    @importer = Importers::PdfEcad.new("#{Rails.root}/resources/careqa.pdf")
  end

  it "should list all works" do
    @importer.works.count.should == 130
    @importer.holders.count.should == 241
    @importer.works[0][:iswc].should == "T-039.782.970-7"
    @importer.works[0][:right_holders][0][:pseudos][0][:name].should == "CARLOS CAREQA"
    @importer.works.last[:external_ids][0][:source_id].should == "126227"
    @importer.works[9][:right_holders].size.should == 4
    @importer.works[9][:right_holders][2][:share].should == 25.00

    @importer.works[2][:right_holders][1][:pseudos][0].should be_nil
    @importer.works[2][:right_holders][1][:role].should == "Author"
  end

  it "should recognize all roles" do
    # 324 - 4882          CARLOS DE SOUZA                       CARLOS CAREQA             582.66.28.18 ABRAMUS          V   16,66                        1
    # 325 - 22824         THOMAS ALAN WAITS                     TOM WAITS                 076.34.68.52 ASCAP            CA 83,34                         2
    # 332 - 525304        GLAUCIA NASSER DE CARVALHO            GLAUCIA NASSER            489.81.25.00 ABRAMUS          C   40,00                        3
    @importer.right_holder(@importer.lines[324])[:role].should == "Versionist"
    @importer.right_holder(@importer.lines[325])[:role].should == "Author"
    @importer.right_holder(@importer.lines[332])[:role].should == "Author"
  end

  it "should recognize a right holder for 100% line" do
    line = @importer.lines[346]
    #"4882         CARLOS DE SOUZA                          CARLOS CAREQA            582.66.28.18 ABRAMUS          CA   100,                        1"
    rh = @importer.right_holder(line)
    rh[:name].should == "CARLOS DE SOUZA"
    rh[:pseudos][0][:name].should == "CARLOS CAREQA"
    rh[:pseudos][0][:main].should == true
    rh[:role].should == "Author"
    rh[:society_name].should == "ABRAMUS"
    rh[:ipi].should == "582662818"
    rh[:external_ids][0][:source_name].should == "Ecad"
    rh[:external_ids][0][:source_id].should == "4882"
    rh[:share].should == 100
  end

  it "should recognize share for broken percent" do
    line = @importer.lines[399]
    #"16863        EDILSON DEL GROSSI FONSECA               EDILSON DEL GROSSI                     SICAM           CA 33,33                         2"

    rh = @importer.right_holder(line)
    rh[:name].should == "EDILSON DEL GROSSI FONSECA"
    rh[:pseudos][0][:name].should == "EDILSON DEL GROSSI"
    rh[:share].should == 33.33
    rh[:ipi].should be_nil
  end

  it "should recognize share in right holder line" do
    line = @importer.lines[383]
    #"741          VELAS PROD. ARTISTICAS MUSICAIS E        VELAS                    247.22.09.80 ABRAMUS           E   8,33 20/09/95               2"

    rh = @importer.right_holder(line)
    rh[:name].should == "VELAS PROD. ARTISTICAS MUSICAIS E"
    rh[:share].should == 8.33
  end

  it 'should have the right share when date is stick to share' do
    line = @importer.lines[198]
    #"85654         DC CONSULTORIA LTDA.                  SETEMBRO EDICOES          284.82.75.27 UBC              E   10,0021/01/09                2"
    rh = @importer.right_holder(line)
    rh[:name].should == "DC CONSULTORIA LTDA."
    rh[:share].should == 10.00
  end

  it "should return nil if it is not a right_holder" do
    line = @importer.lines[289]
    #"3810796       -   .   .   -          O RESTO E PO                                                LB             18/03/2010"
    rh = @importer.right_holder(line)
    rh.should be_nil
  end

  it "should recognize work in line" do
    line = "3810796       -   .   .   -          O RESTO E PO                                                LB             18/03/2010"
    work = @importer.work(line)
    work.should_not be_nil
    work[:iswc].should == "-   .   .   -"
    work[:title].should == "O RESTO E PO"
    work[:external_ids][0][:source_name].should == "Ecad"
    work[:external_ids][0][:source_id].should == "3810796"
    work[:situation].should == "LB"
    work[:created_at].should == "18/03/2010"
  end

  it 'should recognize work if there is no date' do
    line = "740          T-039.026.395-2         OS OUTROS                                                   LB"
    work = @importer.work(line)
    work.should_not be_nil
    work[:iswc].should == "T-039.026.395-2"
    work[:title].should == "OS OUTROS"
    work[:external_ids][0][:source_name].should == "Ecad"
    work[:external_ids][0][:source_id].should == "740"
    work[:situation].should == "LB"
    work[:created_at].should == ""
  end

end
