
--local stringx = require"stringx";
--local s = stringx.trim(" \t\nasdfdsafdsa中文asdfdsafdsa\n   ");
--print('[' .. s .. ']', stringx.contains(s, "afd") )

--[[
  主界面
]]
local iup = assert(require "iuplua")

--默认使用本机GBK编码
iup.SetGlobal('UTF8MODE','YES')
iup.SetGlobal('UTF8MODE_FILE','YES') --[Windows Only]

local components = {

  log = iup.multiline{expand="YES",value=dirprint, VISIBLELINES="10", font='TIMES_NORMAL_12', READONLY="YES"},
  text_location = iup.text{expand="HORIZONTAL", id="text_location", rastersize="450x"},
  btn_browse = iup.button{title="浏览目录...", rastersize="x22",id="btn_browse"},
  btn_browse_dir = iup.button{title="浏览文件...", rastersize="x22",id="btn_browse_dir"},
  btn_import = iup.button{title=" 导入 ", rastersize="x22",id="btn_import"},
  progressbar = iup.progressbar{ MIN =0, MAX=100, DASHED=1,EXPAND='HORIZONTAL',rastersize="x20" },
  encoding_list = iup.list{"UTF-8", "ANSI" ; value = 1 , dropdown="YES", title="生成编码"}
}

 components.appendLog = function( msg )
  if #components.log.value then
    components.log.value =  components.log.value .. '\n' ..  msg
  else
    components.log.value =  msg
  end

end

function default (item)
	return iup.DEFAULT
end

function about (item)
	iup.Message ("关于", "固定资产台账管理工具\nPowered by IUP")
	return iup.DEFAULT
end

function close (item)
	return iup.CLOSE
end


function components.btn_browse:action()
	local dlg = iup.filedlg{dialogtype="DIR"}
	dlg:popup()
	if dlg.status == "0" then
		components.text_location.value = dlg.value
	end
end
function components.btn_browse_dir:action()
	local dlg = iup.filedlg{dialogtype="FILE", filter="*.xlsx"} --*.xls;*.xlsx
	dlg:popup()
	--0 存在, 1 新建 -1 取消
	if dlg.status == "0" then
		--iup.Message('文件名', dlg.value)
		components.text_location.value = dlg.value

	end

end

--======================================================
function connectToDB(item)
	print(item.active)
	item.active='NO'
	-- iup.SetAttribute(self, "active","NO") -- error ?
	--use progress
  local md = require"actions/connectDB"

	local c,e = md.do_connect()
	print (c,e)

	item.active='YES'
end

function components.btn_import:action()
	if components.text_location.value == '' then
    iup.Message("错误",'请选择文件!')
    return
  end
  print("导入...", components.text_location.value)

  local md = require"actions/import_assets"

  components.btn_import.active='NO'
  md.do_import(components, iup)
  components.btn_import.active='YES'

end

local menu_template = {
"文件(&F)",{
"导入本地数据库...",default,
"-",nil,
"Exit",close,
},
"配置(&P)",{
"连接数据库...",connectToDB,
"格式",{
"DOS",default,
"UNIX",default
}
},
"关于(&A)",{

"帮助",default,
"关于",about

}
}

--[[
  helper
]]
function create_menu(templ)
	local items = {}
	for i = 1,#templ,2 do
		local label = templ[i]
		local data = templ[i+1]
		if type(data) == 'function' then
			item = iup.item{title = label}
			item.action = (function () return data(item) end)
		elseif type(data) == 'nil' then
			item = iup.separator{}
		else
			item = iup.submenu {create_menu(data); title = label}
		end
		table.insert(items,item)
	end
	return iup.menu(items)
end

local menu = create_menu(menu_template)

assert(require "iupluacontrols")

local tab1 = iup.vbox
  {
    iup.label{title="请输入固定资产明细表文件(Excel2007+格式): "},
    iup.hbox
    {
      components.text_location,
      --btn_browse,
      components.btn_browse_dir,
      --encoding ANSI or UTF-8
      components.encoding_list,

      components.btn_import

      ; margin="5x5"
    },
    components.log,
    components.progressbar
    ,tabtitle="导入本地数据库"
}

assert (require("iupluamatrixex") )
local mat = iup.matrix {   --depends on the CD library
    numcol=5,
    numlin=1,
    numcol_visible=5,
    numlin_visible=1,
    expand = "HORIZONTAL",
    resizematrix = "YES"}

  mat:setcell(0,0,"序号")
  mat:setcell(1,0,"1")

local r_mat = iup.matrix {   --depends on the CD library
    numcol=5,
    numlin=1,
    numcol_visible=5,
    numlin_visible=1,
    expand = "HORIZONTAL",
    resizematrix = "YES"}

  r_mat:setcell(0,0,"序号")
  r_mat:setcell(1,0,"1")

local  title_rastersize="70x"
local tab2 = iup.vbox
  {
     iup.hbox
      {
        iup.label{title="资产编号: ",rastersize=title_rastersize},
        iup.text{ id="no", rastersize="100x"},
        iup.label{title="资产标签号: ",rastersize=title_rastersize},
        iup.text{ id="tag", rastersize="100x"},
        iup.label{title="资产名称: ",rastersize=title_rastersize},
        iup.text{ id="name", rastersize="100x"},
        iup.label{title="资产分类: ",rastersize=title_rastersize},
        iup.text{ id="cat", rastersize="100x"},
      },
      iup.hbox
      {

        iup.label{title="型号: ",rastersize=title_rastersize},
        iup.text{ id="model", rastersize="100x"},
        iup.label{title="厂家: ",rastersize=title_rastersize},
        iup.text{ id="maker", rastersize="100x"},
        iup.label{title="责任人: ",rastersize=title_rastersize},
        iup.text{ id="responser", rastersize="100x"},
        iup.label{title="地点: ",rastersize=title_rastersize},
        iup.text{ id="address", rastersize="100x"},
      },
      mat,
     tabtitle="本地数据库查询"
}

---[[
local tab3 = iup.vbox
  {
      iup.hbox
      {
        iup.label{title="资产编号: ",rastersize=title_rastersize},
        iup.text{ id="r_no", rastersize="100x"},
        iup.label{title="资产标签号: ",rastersize=title_rastersize},
        iup.text{ id="r_tag", rastersize="100x"},
        iup.label{title="资产名称: ",rastersize=title_rastersize},
        iup.text{ id="r_name", rastersize="100x"},
        iup.label{title="资产分类: ",rastersize=title_rastersize},
        iup.text{ id="r_cat", rastersize="100x"},

        iup.button{title="配置...",rastersize=title_rastersize},
      },
      iup.hbox
      {
        iup.label{title="型号: ",rastersize=title_rastersize},
        iup.text{ id="r_model", rastersize="100x"},
        iup.label{title="厂家: ",rastersize=title_rastersize},
        iup.text{ id="r_maker", rastersize="100x"},

        iup.label{title="责任人: ",rastersize=title_rastersize},
        iup.text{ id="r_responser", rastersize="100x"},
        iup.label{title="地点: ",rastersize=title_rastersize},
        iup.text{ id="r_address", rastersize="100x"},

        iup.button{title="查询",rastersize=title_rastersize},
      },
      iup.hbox
      {
        iup.label{title="SQL: ",rastersize=title_rastersize},
        iup.text{ id="r_sql", expand='YES'},
        iup.button{title="SQL查询",rastersize=title_rastersize},
      },
      r_mat,
     tabtitle="远程数据库查询"
}

--]]

local tabs = iup.tabs{tab1,tab2,tab3, expand='YES'}
local dialog = iup.dialog
{

tabs
; title="固定资产台账管理工具" , margin="3x3", menu= menu
} -- size="500x400"

--[[
frame test
frame.fgcolor = "255 0 0"
frame.size    = EIGHTHxEIGHTH
frame.title   = "This is the frame"
frame.margin  = "10x10"

-- Creates dialog
--local dialog = iup.dialog{frame};
]]



function main()
	dialog:showxy(iup.CENTER, iup.CENTER)

	if (iup.MainLoopLevel()==0) then
  		iup.MainLoop()
	end
end
