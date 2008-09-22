class EnginesController < ApplicationController
  # GET /engines
  # GET /engines.xml
  def index
    @engines = Engine.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @engines }
    end
  end

  # GET /engines/1
  # GET /engines/1.xml
  def show
    @engine = Engine.find(params[:id])
	data = Engine.find(params[:id], :select => "rule")
	conditions = data.rule
	
	conditions.gsub!(/:-/,'')
	conditions.gsub!(/\),/,'::')
	conditions.gsub!(/\(/,',')
	conditions.gsub!(/\)/,'')
	conditions.gsub!(/\]/,'')
	conditions.gsub!(/\[/,'')
	conditions = conditions.split(/::/)

	@conditionList = conditions
	status = conditionMatching(@conditionList)
	
	if(status)
		@output += ",true"
	else
		@output += ",false"
	end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @engine }
    end
  end

	def conditionMatching(conditionList)
		n = 0
		# 変数名　チェック用　正規表現
		reg_var = /(^[A-Z]+[0-9]*[a-z]*[0-9]*$)/
		# 条件式評価用　正規表現
		reg = /(^[A-Z]+[0-9]*[a-z]*[0-9]*\s*)(!=|<=|>=|==|<|>)(\s*[0-9]+$)/ # ex.) Point <= 30
		reg2 = /(^[0-9]+\s*)(!=|<=|>=|==|<|>)(\s*[A-Z]+[0-9]*[a-z]*[0-9]*$)/ # ex.) 30 >= Point
		reg_where = /(.+)(!=|<=|>=|==|<|>)(.+)/	#test_name取得用
		# 変数格納用テーブル
		var_tbl = Array.new
		while n < conditionList.length do
			condition = conditionList[n].strip.split(/,/)
			case condition[0]
				# 現在テストの得点しか取得できない
				# 実装が最低限過ぎ，拡張性がなさすぎ
				# あまりにもアレすぎてふざ（ｒｙ
				# 現在の問題点
				# ・ルール中にスペースを入れられない（rubyかrailsのバージョン？）→解決（正規表現・コードの修正）
				# ・変数の２つ以上の比較に対応できない ex. 80 > PSum, PSum >= 30
			when /test/
				reg_var =~ condition[1]
				var_name = $1
				
				tran_firstall = condition[2]
				tran_select = condition[3]
				# test_name,time,pointを取得
				# tran_whereに直接代入
				# test_nameだけは別に取得，"and","=="以外の場合は今のところ考えない
				#tran_where = condition[4]
				where = condition[4].split(/and/)
				tran_where = nil
				m = 0
				while m < where.length do
					reg_where =~ where[m]
					if($1.strip == 'test_name' && $2 == '==')
						test_name = $3.strip.gsub(/\'/,'')
					else
						if(!tran_where)
							tran_where = where[m]
						else
							tran_where += ' and ' + where[m]
						end
					end
					m += 1
				end
				
				tran_order = condition[5]
				
				# whereをどうやって取得？
				#res = TestLog.getTestStatus(self[:user_id],self[:ent_seq_id],test_name,tran_select,tran_firstall,tran_where,tran_order)
				@output = "#{var_name},#{test_name},#{tran_select},#{tran_firstall},#{tran_where},#{tran_order}"
				res = 50
=begin
				if(condition[3] == "point") # test_logの修正が必要
					res = TestLog.getSumpoint(self[:user_id],self[:ent_seq_id],tran_firstall,tran_where,tran_order)
					#res = TestLog.getSumPoint(self[:user_id],self[:ent_seq_id],test_name)
				else if(condition[3] == "time") # 時間取得自体ができないので後回し
					#res = TestLog.getTestTime(self[:user_id],self[:ent_seq_id],tran_where,tran_order)
				end
=end
				
				if var_name
					var_tbl.push([var_name,res.to_i])
				end
			else
				# 条件式の評価
				# フラグ使わなくて良い方法？
				if (reg =~ condition[0])
					var_name = $1.strip # 変数名
					symbol = $2 # 式
					value1 = $3.strip.to_i # 値
					value_left_flag = false # 条件式の値が左辺にあるか否か　フラグ
				elsif (reg2 =~ condition[0])
					var_name = $3.strip
					symbol = $2
					value1 = $1.strip.to_i
					value_left_flag = true
				end
				
				# 変数に格納されている値を取得
				value2 = nil
				var_tbl.each do |v|
					if v[0] == var_name
						value2 = v[1]
					end
				end
				
				if value2
					case symbol
					when /==/
						flag = value2 == value1
					when /!=/
						flag = value2 != value1
					when /<=/
						if value_left_flag
							flag = value1 <= value2
						else
							flag = value2 <= value1
						end
					when />=/
						if value_left_flag
							flag = value1 >= value2
						else
							flag = value2 >= value1
						end
					when /</
						if value_left_flag
							flag = value1 < value2
						else
							flag = value2 < value1
						end
					when />/
						if value_left_flag
							flag = value1 > value2
						else
							flag = value2 > value1
						end
					end
					unless flag
						return false
					end
				else
					return false
				end
			end
			n += 1
		end
	
		return true
	end


  # GET /engines/new
  # GET /engines/new.xml
  def new
    @engine = Engine.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @engine }
    end
  end

  # GET /engines/1/edit
  def edit
    @engine = Engine.find(params[:id])
  end

  # POST /engines
  # POST /engines.xml
  def create
    @engine = Engine.new(params[:engine])

    respond_to do |format|
      if @engine.save
        flash[:notice] = 'Engine was successfully created.'
        format.html { redirect_to(@engine) }
        format.xml  { render :xml => @engine, :status => :created, :location => @engine }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @engine.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /engines/1
  # PUT /engines/1.xml
  def update
    @engine = Engine.find(params[:id])

    respond_to do |format|
      if @engine.update_attributes(params[:engine])
        flash[:notice] = 'Engine was successfully updated.'
        format.html { redirect_to(@engine) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @engine.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /engines/1
  # DELETE /engines/1.xml
  def destroy
    @engine = Engine.find(params[:id])
    @engine.destroy

    respond_to do |format|
      format.html { redirect_to(engines_url) }
      format.xml  { head :ok }
    end
  end
end
