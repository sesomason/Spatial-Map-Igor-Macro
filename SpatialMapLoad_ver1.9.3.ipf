#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


//  Script to generate spatial map of ARPES intensity
//  written in Igor 8.08 (64 bit)
//  
//  Seigo Soiuma,    Tohoku University  
//	 2020, Nov
//  last update  2021, 1st, July

//	[使い方]		(1) "path"で空間mapしたデータフォルダを指定
//					(2) 2D or 1D でmappingの次元を選択
//					(3) 空間マップのパラメーターを入力
//						xs: x方向の初期値、step: x方向のstep (単位はxsと同じ)、n: x方向のstep数 
//		(1Dでは無視)	ys: y方向の初期値、step: y方向のstep (単位はxsと同じ)、n: y方向のstep数 
//					(4) "Map!!"で ARPES dataの全積分値の空間mapを生成. 
//						 SpatialMapという名前で保存される。
//
// ver 1.2  	ibwデータ(igorのバイナリ形式)の読み込みに対応
// ver 1.3   	(機能追加1) 空間mapにおいてARPES dataの任意の領域の積分値を指定可能
//					(機能追加2) Datashowと連動して、空間map上のカーソルを移動させてその位置でのAREPS dataを表示
//								  DataOpen v1.3.0.1以降でないと機能しない
// 		   	(機能追加3) "show"ボタンを追加。SpatialMapをワンボタンで表示
//
//	[使い方:機能追加1]	(1)	ARPES data (例えばDataShowの表示matrixであるShowM)で積分したい四角の領域の
//									左下隅と右上隅のポイント位置を読み取る	
//							(2)	box 一段目のx,yに左下隅のポイント値、二段目のx,yに右上隅のポイント値を入力	
//							(3)	AREPS dataをアクティブにした状態で"app"ボタンを押すと指定した積分範囲が赤いboxで表示される
//									(これは確認のためで空間map生成には必要ない)
//							(4)	boxというチェックボックスにチェックを入れる。チェックをはずすとmapは全積分値に切り替わる
//							(5)	通常通りにmapすれば、boxで指定した積分値のmapが得られる。保存先はSpatialMap
//
//	[使い方:機能追加2]	(1)	"path"と同じフォルダを、DataShowにおいても"path"で指定する
//							(2)	生成した空間mapの表示データウィンドウをアクティブにする
//							(3)	"Cur"のボタンを押す。(2)のウィンドウに赤いboxが表示される
//							(4)	チェックボックス"link"にチェックを入れる
//							(5)	px,pyの値を動かすと、赤いカーソルが空間map上を動き、その点のAREPS dataがDataShowに表示sれる
//
// ver 1.4  	データファイルのなかにigorデータ以外のファイルがあった場合、これを読み込みから除くように修正
//					ver 1.3以前のマクロで読み込んだファイルは最初の一点に「0」が入ってしまう可能性や、２行目からデータがずれる可能性がある
//
// ver 1.5  	boxチェックにりよるデータの積分範囲の指定を1Dにも拡張。今まで2Dしかできなかった。box x　に積分したい領域をポイント数で
//					入力すればOK
//
// ver 1.6  	(機能追加1) ver1.3においてARPES dataの表示を他のマクロ(DataShow)に頼っていたのをやめて、stand aloneでデータを表示できるようにした
//	(stand alone)	[使い方]　　一番したの青色の"shw"ボタンで、その左のフィールドのファイルのデータが表示される
// 			 	(機能追加2) boxボタンで表示するboxのx値y値を、spatial mapように読み込んでいるloadmatから直接計算するようにした (ver1.5まではDataShow
//								　のmatrixを使っていた)
// ver 1.7  	読み込むデータリストの更新機能をmapボタンの実行にも付与
//
// vre 1.8		MBS-A1のtxtデータ(テキスト形式)とkrx(バイナリ形式)の読み込みに対応
// (2021.7.1)
//
//	ver 1.9	1. SESのデータが複数のregionを測定している場合に対応
//				[使い方]　Mapボタンを押した後、　どのregionのデータをmapするかをポップウィンドウで選択
//				2. mapデータ上のカーソル(赤box)をwindow上でカーソルキー(上下左右)で直接ごかせるようになった。
//				[使い方] みたいmapデータをトップにした状態で、Curボタンを押す。赤いboxとクロスラインが表示されればOK。
//					mapデータ上でカーソルキーで操作して、赤boxとクロスラインが連動すればOK。
//					動きが連動しない場合、またクロスラインが動いても座標が連動しない場合は、Curボタンを二回おしてリフレッシュすればよい
//				3.	赤boxと連動して表示される、その点のデータも複数regionに対応 (SESのみ)
//				[使い方]	パネルの下から2行目に、「wn」という数値設定を追加したので、その数値を変えてみたいregionを
//					みたいregionを選択する。wn数値設定の横にregion名が表示される。

Window SpatMapLoad() : Panel
	PauseUpdate; Silent 1		// building window...
	SML_Setup()
	NewPanel /W=(739,142,915,332)
	ModifyPanel cbRGB=(1,52428,52428)
	SetDrawLayer UserBack
	DrawText 8,106,"box"
	Button SML__Button_pathset,pos={4.00,7.00},size={43.00,16.00},proc=SML_button_pathset,title="path"
	Button SML__Button_pathset,font="Helvetica",fSize=10,fColor=(32768,65535,49386)
	Button SML_done_button,pos={121.00,169.00},size={33.00,16.00},proc=SML_button_done,title="done"
	Button SML_done_button,fSize=10,fColor=(65535,16385,16385)
	PopupMenu SML_popup_1D2D,pos={4.00,28.00},size={47.00,23.00},proc=SML_PopMenu_SetFlagDimension
	PopupMenu SML_popup_1D2D,mode=2,popvalue="2D",value= #"\"1D;2D\""
	SetVariable SML_Setvar_StartX,pos={10.00,53.00},size={50.00,14.00},title="Xs"
	SetVariable SML_Setvar_StartX,limits={-inf,inf,0},value= root:SpatialMapLoad:SML_xstart
	SetVariable SML_Setvar_StepX,pos={62.00,53.00},size={66.00,14.00},title="step"
	SetVariable SML_Setvar_StepX,limits={-inf,inf,0},value= root:SpatialMapLoad:SML_xstep
	SetVariable SML_Setvar_numX,pos={128.00,53.00},size={44.00,14.00},title="n"
	SetVariable SML_Setvar_numX,limits={-inf,inf,0},value= root:SpatialMapLoad:SML_xnum
	SetVariable SML_Setvar_StartY,pos={10.00,68.00},size={50.00,14.00},title="Ys"
	SetVariable SML_Setvar_StartY,limits={-inf,inf,0},value= root:SpatialMapLoad:SML_ystart
	SetVariable SML_Setvar_StepY,pos={62.00,68.00},size={66.00,14.00},title="step"
	SetVariable SML_Setvar_StepY,limits={-inf,inf,0},value= root:SpatialMapLoad:SML_ystep
	SetVariable SML_Setvar_numY,pos={128.00,68.00},size={44.00,14.00},title="n"
	SetVariable SML_Setvar_numY,limits={-inf,inf,0},value= root:SpatialMapLoad:SML_ynum
	SetVariable SML_Setvar_FolderName,pos={50.00,7.00},size={121.00,14.00},title=" "
	SetVariable SML_Setvar_FolderName,value= root:SpatialMapLoad:SML_foldername
	Button SML_Button_Map,pos={57.00,23.00},size={73.00,23.00},proc=SML_button_mapping,title="Map!!"
	Button SML_Button_Map,fSize=16
	SetVariable SML_Setvar_box1x,pos={33.00,85.00},size={39.00,14.00},proc=SML_SetVarIntegBoxDef,title="x"
	SetVariable SML_Setvar_box1x,limits={-inf,inf,0},value= root:SpatialMapLoad:SML_integbox1x
	SetVariable SML_Setvar_box1y,pos={71.00,85.00},size={38.00,14.00},proc=SML_SetVarIntegBoxDef,title="y"
	SetVariable SML_Setvar_box1y,limits={-inf,inf,0},value= root:SpatialMapLoad:SML_integbox1y
	SetVariable SML_Setvar_box2y,pos={71.00,99.00},size={38.00,14.00},proc=SML_SetVarIntegBoxDef,title="y"
	SetVariable SML_Setvar_box2y,limits={-inf,inf,0},value= root:SpatialMapLoad:SML_integbox2y
	SetVariable SML_Setvar_box2x,pos={32.00,99.00},size={39.00,14.00},proc=SML_SetVarIntegBoxDef,title="x"
	SetVariable SML_Setvar_box2x,limits={-inf,inf,0},value= root:SpatialMapLoad:SML_integbox2x
	Button SLM_button_appendbox,pos={120.00,84.00},size={37.00,16.00},proc=SML_button_appendbox,title="app"
	Button SLM_button_appendbox,fSize=10,fColor=(65535,65535,0)
	CheckBox SML_checkbox_integcheck,pos={124.00,102.00},size={34.00,16.00},proc=SML_Check_integbox,title="box"
	CheckBox SML_checkbox_integcheck,variable= root:SpatialMapLoad:SML_flagIntegBox
	Button SLM_Button_display,pos={134.00,26.00},size={35.00,20.00},proc=SML_button_display,title="show"
	Button SLM_Button_display,fSize=10,fColor=(40969,65535,16385)
	SetVariable SML_Setval_cursor_x,pos={10.00,117.00},size={55.00,14.00},proc=SML_setvar_changepxpy,title="px"
	SetVariable SML_Setval_cursor_x,limits={0,1000,1},value= root:SpatialMapLoad:SML_px
	SetVariable SML_Setval_cursor_y,pos={68.00,117.00},size={51.00,14.00},proc=SML_setvar_changepxpy,title="py"
	SetVariable SML_Setval_cursor_y,limits={0,1000,1},value= root:SpatialMapLoad:SML_py
	Button SLM_button_appendCursor,pos={124.00,123.00},size={27.00,22.00},proc=SML_button_appendcursor,title="Cur"
	Button SLM_button_appendCursor,fSize=10,fColor=(40969,65535,16385)
	Button SLM_button_showloadmat,pos={123.00,149.00},size={29.00,16.00},proc=SML_button_showloadmat,title="shw"
	Button SLM_button_showloadmat,fSize=10,fColor=(16385,49025,65535)
	SetVariable SML_Setval_SESdatanum,pos={9.00,151.00},size={50.00,14.00},proc=SML_SetVar_setdatanum,title="wn"
	SetVariable SML_Setval_SESdatanum,limits={1,5,1},value= root:SpatialMapLoad:SML_sesdatanum
	ValDisplay SML_valdisp_xvalue,pos={25.00,134.00},size={44.00,13.00}
	ValDisplay SML_valdisp_xvalue,limits={0,0,0},barmisc={0,1000}
	ValDisplay SML_valdisp_xvalue,value= #"root:SpatialMapLoad:SML_pxvalue"
	ValDisplay SML_valdisp_yvalue,pos={73.00,134.00},size={44.00,13.00}
	ValDisplay SML_valdisp_yvalue,limits={0,0,0},barmisc={0,1000}
	ValDisplay SML_valdisp_yvalue,value= #"root:SpatialMapLoad:SML_pyvalue"
	TitleBox title0,pos={127.00,134.00},size={50.00,20.00}
	TitleBox SML_title_filename,pos={25.00,167.00},size={80.00,17.00}
	TitleBox SML_title_filename,labelBack=(65535,65535,65535)
	TitleBox SML_title_filename,variable= root:SpatialMapLoad:SML_filername,fixedSize=1
	TitleBox SML_title_igornameitem,pos={61.00,150.00},size={52.00,15.00}
	TitleBox SML_title_igornameitem,labelBack=(65535,65535,65535),fSize=7
	TitleBox SML_title_igornameitem,variable= root:SpatialMapLoad:SML_IgorNameItem,fixedSize=1
EndMacro


Function SML_Setup()
	
	if (DataFolderRefStatus(dfr) ==0)
		NewDataFolder/O root:SpatialMapLoad
	endif
	DFREF dfr = root:SpatialMapLoad
	
	String/G dfr:SML_folderpath
	String/G dfr:SML_foldername
	String/G dfr:SML_filername
	String/G dfr:SML_DataList
	
	Variable/G dfr:SML_xstart=0, dfr:SML_xstep=0.01, dfr:SML_xnum=5
	Variable/G dfr:SML_ystart=0, dfr:SML_ystep=0.01, dfr:SML_ynum=5

	Variable/G dfr:SML_flagDimnsion=2
	Variable/G dfr:SML_flagIntegBox=0
	Variable/G dfr:SML_flagLinkShowM=0

	Variable/G dfr:SML_integbox1x=0, dfr:SML_integbox1y=0, dfr:SML_integbox2x=10, dfr:SML_integbox2y=10 
	
	make/N=(100,100)/D/O dfr:loadmat,dfr:loadmat1,dfr:loadmat2,dfr:loadmat3,dfr:loadmat4
	make/N=(100,100)/D/O dfr:loadmat5,dfr:loadmat6,dfr:loadmat7,dfr:loadmat8

	Make/N=5/D/O dfr:integbox_y,dfr:integbox_x
	Make/N=5/D/O dfr:integline_y,dfr:integline_x

	
	Variable/G dfr:SML_px,dfr:SML_py
	Variable/G dfr:SML_pxvalue,dfr:SML_pyvalue
	Make/N=5/D/O dfr:pointAx, dfr:pointAy
	String/G dfr:SML_CurrentWinName

	
	
	Variable/G dfr:SML_sesdatanum = 1
	String/G dfr:SML_IgorWaveList
	String/G dfr:SML_IgorNameItem


End




Function SML_button_pathset(ctrlName) : ButtonControl
	String ctrlName
	
	DFREF dfr = root:SpatialMapLoad
	SVAR folderpath = dfr:SML_folderpath
	SVAR foldername = dfr:SML_foldername

	newpath/O tempath 
	if (V_flag)
	return -1
	endif
	pathinfo/s tempath
	folderpath = s_path
	
	variable numitems = ItemsInList(folderpath,":")
	foldername = StringFromList((numitems-1), folderpath,":")
	
	SML_MListUPdata()
	SML_Set_SESIgorMutiplewaveData()
	
end

Function SML_button_done(ctrlName) : ButtonControl
	String ctrlName

	Dowindow/K SpatMapLoad
	
End



Function SML_PopMenu_SetFlagDimension(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	DFREF dfr = root:SpatialMapLoad
	NVAR flagD = dfr:SML_flagDimnsion

	flagD = popNum
	
	switch(flagD)	
		case 1:	
			SetVariable SML_Setvar_StartY disable=2
			SetVariable SML_Setvar_StepY disable=2
			SetVariable SML_Setvar_numY disable=2
			SetVariable SML_Setval_cursor_y disable=2
			ValDisplay SML_valdisp_yvalue disable=2
			SetVariable SML_Setvar_box1y disable=2	
			SetVariable SML_Setvar_box2y disable=2	

			break	
		case 2:	
			SetVariable SML_Setvar_StartY disable=0
			SetVariable SML_Setvar_StepY disable=0
			SetVariable SML_Setvar_numY disable=0
			SetVariable SML_Setval_cursor_y disable=0
			ValDisplay SML_valdisp_yvalue disable=0
			SetVariable SML_Setvar_box1y disable=0
			SetVariable SML_Setvar_box2y disable=0	
			break	
	endswitch

End


Function SML_MListUPdata()

	DFREF dfr = root:SpatialMapLoad

	String templist_pxt,templist_pxp,templist_ibw,templist
	String templist_txt,templist_krx
	SVAR Mlist = dfr:SML_Datalist
	SVAR folderpath = dfr:SML_folderpath
	
	variable cond1
	
	NewPath/O/Q tempath folderpath
	
	templist_pxt = indexedfile (tempath,-1,".pxt")
	templist_pxp = indexedfile (tempath,-1,".pxp")
	templist_ibw = indexedfile (tempath,-1,".ibw")
	templist_txt = indexedfile (tempath,-1,".txt")
	templist_txt = RemoveFromList("mappinginfo.txt",templist_txt)   // Remove mapping info file in spatial map folder taken at BL28
	templist_krx = indexedfile (tempath,-1,".krx")
	
	templist = templist_pxt+templist_pxp+templist_ibw + templist_txt + 	templist_krx
	
	cond1=cmpstr( stringfromlist(0,templist),"")
	if (cond1==0)
		print "first cell is null!!"
	endif
	Mlist = SortList(templist, ";", 16)


End



Function SML_Make2Dmap()

	DFREF dfr = root:SpatialMapLoad
	SVAR  folderpath = dfr:SML_folderpath
	SVAR filenamelist = dfr:SML_DataList
	NVAR xs = dfr:SML_xstart, xstep = dfr:SML_xstep, xnum = dfr:SML_xnum
	NVAR ys = dfr:SML_ystart, ystep = dfr:SML_ystep, ynum = dfr:SML_ynum
	wave loadmat = dfr:loadmat
	
	
	make/O/D/N=(xnum,ynum) SpatialMap
	make/O/D/T/N=(xnum,ynum) SpatialMapName
	SetScale/P x xs,xstep,"", SpatialMap
	SetScale/P y ys,ystep,"", SpatialMap
	
	NVAR box1x = dfr:SML_integbox1x, box1y = dfr:SML_integbox1y,box2x = dfr:SML_integbox2x, box2y = dfr:SML_integbox2y
	make/O/D/N=((box2x-box1x+1),(box2y-box1y+1)) loadfocusmat
	NVAR flagint = dfr:SML_flagIntegBox
	NVAR sesdatanum=dfr:SML_sesdatanum

	
	variable ii=0,jj=0
	string dataname
	variable filenumber
	variable cond1, cond2, cond3, cond4
	variable nn = 1
	variable  finenumbermax = xnum * ynum
	variable countindex = 0
	
	if (flagint==0)
		print "map intensity correponds to total int of arpes mat"
	elseif (flagint==1)
		print "map intensity correponds to partial int of arpes mat specified by box"
	endif

	Do	
		ii = 0
		Do
		
		filenumber = jj * xnum + ii
		dataname = StringFromList(filenumber, filenamelist,";")
		cond1 = StringMatch(dataname,"*.pxt")||StringMatch(dataname,"*.pxp")
		cond2 = StringMatch(dataname,"*.ibw")
		cond3 = StringMatch(dataname,"*.txt")
		cond4 = StringMatch(dataname,"*.krx")

		if (cond1==1)
		
			if (ii==0 && jj==0)
				SML_Choose_SES_Wave()
			endif

			SML_SES2D(loadmat,folderpath,dataname,sesdatanum)
	

		elseif(cond2==1)
		
			if (ii==0 && jj==0)
				SML_Choose_SES_Wave()
			endif

			SML_SESBinary(loadmat,folderpath,dataname,sesdatanum)
			
		elseif(cond3==1)
			SML_A1txt2D(loadmat,folderpath,dataname)
			
		elseif(cond4==1)
			SML_krxfile2D(loadmat,folderpath,dataname)

		else	
			loadmat=0
			dataname = ""
			
		endif
		
		if (flagint==0)
				wavestats/Q loadmat
				SpatialMap[ii][jj]=v_sum
		elseif (flagint==1)
				loadfocusmat[][] = loadmat[box1x+p][box1y+q]
				wavestats/Q loadfocusmat
				SpatialMap[ii][jj]=v_sum
		endif
		
		SpatialMapName[ii][jj] = dataname

		// data processing status
		countindex = floor(finenumbermax*(nn/10))
		if (filenumber == countindex)
			print nn*10, " % done"
			nn = nn + 1
		endif
	
		ii = ii +1
		while(ii<xnum)	
		
		jj = jj+1					
	while(jj<ynum)	

	
//	Display;DelayUpdate
//	AppendImage SpatialMap

	//sesdatanum = -1

End

Function SML_Make1Dmap()

	DFREF dfr = root:SpatialMapLoad
	SVAR folderpath = dfr:SML_folderpath
	SVAR filenamelist = dfr:SML_DataList
	NVAR xs = dfr:SML_xstart, xstep = dfr:SML_xstep, xnum = dfr:SML_xnum
	wave loadmat = dfr:loadmat

	
	make/O/D/N=(xnum) SpatialProfile
	SetScale/P x xs,xstep,"", SpatialProfile
	make/O/D/T/N=(xnum,0) SpatialMapName

	
	NVAR box1x = dfr:SML_integbox1x,box2x = dfr:SML_integbox2x
	make/O/D/N=(box2x-box1x+1) loadfocusmat
	NVAR flagint = dfr:SML_flagIntegBox
	NVAR sesdatanum = dfr:SML_sesdatanum
	
	variable ii=0
	string dataname
	variable filenumber
	variable cond1, cond2, cond3, cond4
	variable nn = 1
	variable countindex = 0
	
	
	
	Do		
		filenumber =  ii
		dataname = StringFromList(filenumber, filenamelist,";")
		cond1 = StringMatch(dataname,"*.pxt")||StringMatch(dataname,"*.pxp")
		cond2 = StringMatch(dataname,"*.ibw")
		cond3 = StringMatch(dataname,"*.txt")
		cond4 = StringMatch(dataname,"*.krx")
				
		if (cond1==1)
		
			if (ii==0)
				SML_Choose_SES_Wave()
			endif
	
			SML_SES2D(loadmat,folderpath,dataname,sesdatanum)

			
		elseif (cond2==1)
		
			if (ii==0)
				SML_Choose_SES_Wave()
			endif
			
			SML_SESBinary(loadmat,folderpath,dataname,sesdatanum)
			
		elseif (cond3==1)
			SML_A1txt2D(loadmat,folderpath,dataname)
			
		elseif (cond4==1)
			SML_krxfile2D(loadmat,folderpath,dataname)

		else	
			loadmat = 0
			
		endif
		
		
			if (flagint==0)
				wavestats/Q loadmat
				SpatialProfile[ii]=v_sum
			elseif (flagint==1)
				loadfocusmat[] = loadmat[box1x+p]
				wavestats/Q loadfocusmat
				SpatialProfile[ii]=v_sum
			endif
	
			SpatialMapName[ii][0] = dataname

		ii = ii +1
	while(ii<xnum)	
	
		// data processing status
		countindex = floor(xnum*(nn/10))
		if (filenumber == countindex)
			print nn*10, " % done"
			nn = nn + 1
		endif
	
	display SpatialProfile
	
End



Function SML_SES2D(m0,folderpath,dataname,igordatanum)
wave m0
String folderpath,dataname
variable igordatanum

	variable loaddatanum
	variable numinfolder
	string loadWaveName
	
	Newpath/O/Q pathtodata folderpath
	LOADDATA /p=pathtodata/q /T=load /L=1/O dataname

	setdatafolder root:load			
	loadWaveName = wavename ("",(igordatanum-1),4)
	if (cmpstr(loadWaveName,"")==1)
	duplicate/o root:load:$loadWaveName m0
	endif
	setdatafolder root:load
	killwaves/A
	setdatafolder root:

End


Function SML_A1txt2D(m0,folderpath,dataname)
wave m0
string dataname,folderpath

	Variable refnum 
	Variable v0, v1
	Variable ii
	Variable x0, x1, y0, y1, e0, e1
	
	String header = PadString("", 1200, 32)	// 1200 bytes should do it
	String header_short
	string loadwavename
	
	Newpath/O/Q pathtodata folderpath
	Open/R/p=pathtodata refnum as dataname
	LoadWave/G/M/N=loadM/O/P=pathtodata/Q dataname // 2D map is stord to storeM0
	loadwavename = StringFromList(0,S_wavenames)
	duplicate/o $loadwavename m0
	FSetPos refNum, 1
	FreadLine/T=";"/N=	1200 refNum,header
	v0 = strsearch(header, "DATA:", 0)
	header_short = header[0,v0-1]
	
	e0 = NumberByKey("Start K.E.", header,"\t","\r\n")
	e1 = NumberByKey("End K.E.", header,"\t","\r\n")
	y0 = NumberByKey("ScaleMin", header,"\t","\r\n")
	y1 = NumberByKey("ScaleMax", header,"\t","\r\n")
	
	// (1.3.0.4) in case for Xscalse and Yscale are used in deflector system 
	if (numtype(y0)==2)		
		y0 = NumberByKey("XScaleMin", header,"\t","\r\n") 
		y1 = NumberByKey("XScaleMax", header,"\t","\r\n") 
	endif																
	
	// (1.3.0.4) removing first column if it is energy scale
	// (1.3.0.4) Such column maybe appera in old-type A1 data
	variable d1,d2,s1
	d1 = m0[1][0]-m0[0][0]
	d2 = m0[2][0]-m0[1][0]
	s1 = m0[0][0]
	if (  d1<(1.01*d2) && d1>(0.99*d2) ) 
		if (e0<(1.01*s1) && e0>(0.99*s1))
	 		//print dataname +" inludes energy column"
	 		DeletePoints/M=1 0,1, m0
	 	endif
	endif

	//Redimension/S $w_name								// Converts to SP floating point. Is rather slow.
	SetScale/I x e0, e1, "eV" m0
	SetScale/I y y0, y1, "deg" m0
	Note/K m0, header_short
	
	killwaves/Z $loadwavename	
	Close refnum
	
end


Function SML_krxfile2D(m0,folderpath,dataname) 
wave m0
String dataname,folderpath
	
	Variable refnum
	Variable v0, v1
	Variable n_images, image_pos, image_sizeX, image_sizeY, header_pos
	Variable ii
	Variable x0, x1, y0, y1, e0, e1
	String w_basename = "image_"
	String w_name
	Variable Is64bit

	
	String header = PadString("", 1200, 32)	// 1200 bytes should do it
	String header_short
	
	Newpath/O/Q pathtodata folderpath	
	Open/R/p=pathtodata refnum as dataname
	
	// 32 bit - 64 bit autodetect: 
	// Data is written with little-endian -> The second 32 bit word is 0 for a 64 bit file unless the file contains > 2 10^9 images, which we will exclude.
	FSetPos refNum, 4
	FBinRead/B=3/F=3 refNum, v0
	if (v0 == 0)
		Is64bit = 1
	else
		Is64bit = 0
	endif

	// krax files contain 32 bit / 4 byte integers
	//	FBinRead/B=3/F=3 refNum, v1		//F=3 reads four bytes
	

	
	// size and position of first image:
	// pointers can be 64 bit or 32 bit integers
	// data is 32 bit / 4 byte integers
	if (Is64bit)
		FSetPos refNum, 0
		FBinRead/B=3/F=6 refNum, v1					// F=6 reads 8 byte integer
		n_images = v1/3	
		
		FSetPos refNum, 8									// second number in 64-bit file starts at byte 8
		FBinRead/B=3/F=6 refNum, image_pos			// file-position of first image
		FSetPos refNum, 16
		FBinRead/B=3/F=6 refNum, image_sizeY		// Parallel detection angle
		FSetPos refNum, 24
		FBinRead/B=3/F=6 refNum, image_sizeX		// Energy coordinate
	else
		FSetPos refNum, 0
		FBinRead/B=3/F=3 refNum, v1					//F=3 reads four bytes
		n_images = v1/3	
		
		FSetPos refNum, 4									// second number in file starts at byte 4
		FBinRead/B=3/F=3 refNum, image_pos			// file-position of first image
		FSetPos refNum, 8
		FBinRead/B=3/F=3 refNum, image_sizeY		// seems to be parallel detection angle
		FSetPos refNum, 12
		FBinRead/B=3/F=3 refNum, image_sizeX		// seems to be energy coordinate
	endif

	// autodetect header format and get wave scaling from first header :
	header_pos = (image_pos + image_sizeX * image_sizeY + 1) * 4			// position of first header	
	FSetPos refNum, header_pos		
	FBinRead/B=3 refNum, header
	v0 = strsearch(header, "DATA:", 0)
	header_short = header[0,v0-1]
	
	if (stringmatch(header_short,"Lines*"))			
		// new headers starting with "Lines\t..."
		e0 = NumberByKey("Start K.E.", header_short,"\t","\r\n")
		e1 = NumberByKey("End K.E.", header_short,"\t","\r\n")
		x0 = NumberByKey("ScaleMin", header_short,"\t","\r\n")		// parallel detection
		x1 = NumberByKey("ScaleMax", header_short,"\t","\r\n")
		y0 = NumberByKey("MapStartX", header_short,"\t","\r\n")		// deflector
		y1 = NumberByKey("MapEndX", header_short,"\t","\r\n")

	else																
		// old header
		e0 = NumberByKey("Start K.E.", header_short,"\t","\r\n")
		e1 = NumberByKey("End K.E.", header_short,"\t","\r\n")
		x0 = NumberByKey("XScaleMin", header_short,"\t","\r\n")		// parallel detection
		x1 = NumberByKey("XScaleMax", header_short,"\t","\r\n")
		y0 = NumberByKey("YScaleMin", header_short,"\t","\r\n")		// deflector
		y1 = NumberByKey("YScaleMax", header_short,"\t","\r\n")
	endif
	
	
	 // if krx data is not a normal 2D map, this dataload is pended
	if (n_images!=1)
		print "data is not 2D mat, maybe have higher dimension"
		m0 = 0
		return -1
	endif
	

	Make/O/I/N=(image_sizeX, image_sizeY) databuffer	// note 32 bit integer format (runs faster). Change /I to /S for single precision floating point
	
	ii = 0
	
		if (Is64bit)
			FSetPos refNum, (ii*3 + 1) * 8			// pointers to image positions are at bytes 8, 32, 56,... 
			FBinRead/B=3/F=6 refNum, image_pos		// this is the image position in 32 bit integers. Position in bytes is 4 times that
		else
			FSetPos refNum, (ii*3 + 1) * 4			// pointers to image positions are at bytes 4, 16, 28,... 
			FBinRead/B=3/F=3 refNum, image_pos		// this is the image position in 32 bit integers. Position in bytes is 4 times that
		endif
		
//	FSetPos refNum, (ii*3 + 1) * 4			// pointers to image positions are at bytes 4, 16, 28,... 
//	FBinRead/B=3/F=3 refNum, image_pos	// this is the image position in 32 bit integers. Position in bytes is 4 times that
	
	//	read image
	FSetPos refNum, image_pos*4
	FBinRead/B=3/F=3 refNum, databuffer
		
	// read header into string.
		FSetPos refNum, (image_pos + image_sizeX * image_sizeY + 1) * 4	// position of the header
		FBinRead/B=3 refNum, header
		v0 = strsearch(header, "DATA:", 0)
		header_short = header[0,v0-1]
	
//	e0 = NumberByKey("Start K.E.", header,"\t","\r\n")
//	e1 = NumberByKey("End K.E.", header,"\t","\r\n")
//	y0 = NumberByKey("ScaleMin", header,"\t","\r\n")
//	y1 = NumberByKey("ScaleMax", header,"\t","\r\n")
	
	
	Duplicate/O databuffer m0
	//Redimension/S $w_name								// Converts to SP floating point. Is rather slow.
	SetScale/I x e0, e1, "eV" m0
	SetScale/I y x0, x1, "deg" m0
	Note/K m0, header_short
		
	Close refnum
//	KillWaves/Z databuffer
			
end




Function SML_button_mapping(ctrlName) : ButtonControl
	String ctrlName
	
	DFREF dfr = root:SpatialMapLoad
	NVAR flagD = dfr:SML_flagDimnsion
	
	SML_MListUPdata()
	
	switch(flagD)	
		case 1:	
			SML_Make1Dmap()
			break	
		case 2:	
			SML_Make2Dmap()
			break	
	endswitch

End


Function SML_AllmatrixSum(lastnum)
variable lastnum


	DFREF dfr = root:SpatialMapLoad
	SVAR folderpath = dfr:SML_folderpath
	SVAR filenamelist = dfr:SML_DataList
	wave loadmat = dfr:loadmat
	
	variable ii=0
	string dataname
	variable filenumber
	variable cond1
	
	dataname = StringFromList(10, filenamelist,";")
	
	
	SML_SES2D(loadmat,folderpath,dataname,1)
	duplicate/O loadmat Summat
	Summat = 0
		
	
	Do		
		filenumber =  ii
		dataname = StringFromList(filenumber, filenamelist,";")
		cond1 = StringMatch(dataname,"*.pxt")||StringMatch(dataname,"*.pxp")
		
		if (cond1==1)
			SML_SES2D(loadmat,folderpath,dataname,1)
			Summat = Summat + loadmat
		endif
	
		ii = ii +1
	while(ii<lastnum)	

End


Function SML_SESBinary(m0,folderpath,dataname,igornum)
wave m0
String folderpath,dataname
Variable igornum

//	DFREF dfr = root:DataLoadFolder
//	SVAR dataname = dfr:GS_dataname
//	NVAR igormulti = dfr:DataOpen_SES_IgorMultiData
//	wave m0 = dfr:storeM0
	
	variable loaddatanum
	variable numinfolder
	string loadWaveName
	
	Newpath/O/Q pathtodata folderpath
	
	LoadWave/H/P=pathtodata/O/D/Q dataname
	loadWaveName = StringfromList(0,S_waveNames)
//	loaddatanum = igornum  //specify the data from igorfile in which mulitiple data porentially stored
//	numinfolder =  CountObjects("root:load", 1)
//		if (loaddatanum<numinfolder)
//				loadWaveName = wavename ("",loaddatanum,4)
//		else
//				loadWaveName = wavename ("",0,4)
//		endif
			
//	setdatafolder root:
	duplicate/o $loadWaveName m0
	setwavelock 0, $loadWaveName
	killwaves $loadWaveName
			
//	DO_DtShw_GetSESAnaConInfo(m0)  //////////   Info derive for SES data matrix


End

Function SML_SetVarIntegBoxDef(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	DFREF dfr = root:SpatialMapLoad
	wave igx = dfr:integbox_x
	wave igy = dfr:integbox_y
	NVAR box1x = dfr:SML_integbox1x, box1y = dfr:SML_integbox1y,box2x = dfr:SML_integbox2x, box2y = dfr:SML_integbox2y
	
	wave linex = dfr:integline_x

	wave loadmat =  dfr:loadmat1
	NVAR wnum = dfr:SML_sesdatanum
	if (wnum!=1)
		string loadmatname = "loadmat" + num2str(wnum)
		wave loadmat =  dfr:$loadmatname
	endif
	
	variable xstart = Dimoffset(loadmat,0),ystart = Dimoffset(loadmat,1) 
	variable xstep = Dimdelta(loadmat,0),ystep = Dimdelta(loadmat,1) 
	
	igx[0] = xstart + xstep * box1x
	igx[1] = xstart + xstep * box2x
	igx[2] = igx[1] 
	igx[3] = igx[0] 
	igx[4] = igx[0]
	
	igy[0] = ystart + ystep * box1y
	igy[1] = igy[0]
	igy[2] = ystart + ystep * box2y
	igy[3] = igy[2] 
	igy[4] = igy[0]
	
	linex[0] = xstart + xstep * box1x
	linex[1] = linex[0]
	linex[2] = nan
	linex[3] = xstart + xstep * box2x
	linex[4] = linex[3]


End


Function SML_button_appendbox(ctrlName) : ButtonControl
	String ctrlName

	DFREF dfr = root:SpatialMapLoad	
	wave liney = dfr:integline_y
	String  traceList = TraceNameList("", ";", 1), wavelist1
	variable  cond1, datadim
	
	if(cmpstr(ImageNameList("",";"),"")==1)  // data on graphe is 2d
		datadim = 2
	else
		datadim = 1
	endif
	
	switch(datadim)	
		case 2:	
			cond1 = stringmatch(traceList,"*integbox_y*")
			if (cond1==0)
				AppendToGraph :SpatialMapLoad:integbox_y vs :SpatialMapLoad:integbox_x
			elseif (cond1==1)
				RemoveFromGraph integbox_y
			endif
			break
			
		case 1:
		
			wavelist1 = listmatch(traceList,"!integline_y*")
			string wn1 = StringFromList(0,wavelist1)
			wave w = TraceNameToWaveRef("", wn1)
			variable ymax = wavemax(w), ymin =wavemin(w) 
			liney = {ymax,ymin,nan,ymax,ymin}
			
			cond1 = stringmatch(traceList,"*integline_y*")
			if (cond1==0)
				AppendToGraph :SpatialMapLoad:integline_y vs :SpatialMapLoad:integline_x
			elseif (cond1==1)
				RemoveFromGraph integline_y
			endif
			break

	endswitch

			


End


Function SML_button_appendcursor(ctrlName) : ButtonControl
	String ctrlName
	
	DFREF dfr = root:SpatialMapLoad	
	NVAR pxvalue = dfr:SML_pxvalue,pyvalue = dfr:SML_pyvalue
	SVAR cwinname = dfr:SML_CurrentWinName
	
	String  traceList = TraceNameList("", ";", 1)  // Get trace (1dwave) list of Top graph 

	variable  cond1 = stringmatch(traceList,"*pointAy*") // is there pointAy wave?
	
	string mapname
	variable dim
	[dim,mapname] = SML_ReadDataTopWindow()
	cwinname = winname(0,1)
		
	switch(dim)	
		case 1:	// profile case
			if(strlen(csrinfo(G))==0)
				SML_Update_cursor()
				SML_DataLoadTmp()
				cursor /H=1/S=2 G $mapname pxvalue
				SetWindow $cwinname hook(myHook)=SML_CursorProc
			else
				SetWindow $cwinname hook(myHook)=$""
				cursor /K G 
			endif
			break	
		case 2:	// profile case
			if (cond1==0)  // case of appendiong cursor and pointAy box
				cwinname = winname(0,1,1)  // get topwindow name
				AppendToGraph :SpatialMapLoad:pointAy vs :SpatialMapLoad:pointAx
				SML_Update_cursor()
				SML_DataLoadTmp()
				cursor /H=1/I/S=2 G $mapname pxvalue,pyvalue   // append cursor (cross type)
				SetWindow $cwinname hook(myHook)=SML_CursorProc  // hook the curdor to macro of SML_CursorProc
			elseif (cond1==1) //case of removing cursor and pointAy box
				SetWindow $cwinname hook(myHook)=$""  // hook off the curdor 
				RemoveFromGraph pointAy  
				cursor /K G 
			endif
			
			break		
	endswitch
	

End

Function SML_Check_integbox(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	DFREF dfr = root:SpatialMapLoad
	NVAR flag = dfr:SML_flagIntegBox
	
	flag = checked

End

Function SML_button_display(ctrlName) : ButtonControl
	String ctrlName
	wave SpatialMap
	Display;DelayUpdate
	AppendImage SpatialMap
	ModifyImage SpatialMap ctab= {*,*,Terrain256,0}
	SetAxis/A/R left
	
End

Function SML_setvar_changepxpy(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	SML_Update_cursor()

	SML_DataLoadTmp()

End

Function SML_Update_cursor()

	DFREF dfr = root:SpatialMapLoad	
	NVAR sesdatanum=dfr:SML_sesdatanum
	NVAR px = dfr:SML_px, py = dfr:SML_py
	NVAR pxvalue = dfr:SML_pxvalue,pyvalue = dfr:SML_pyvalue
	wave pxw = dfr:pointAx, pyw = dfr:pointAy
	NVAR xs = dfr:SML_xstart, xd = dfr:SML_xstep, xnum = dfr:SML_xnum
	NVAR ys = dfr:SML_ystart, yd = dfr:SML_ystep, ynum = dfr:SML_ynum
	NVAR stepx = dfr:SML_xstep, stepy = dfr:SML_ystep

	if (px>xnum)
	 px = xnum
	endif
	
	if (py>ynum)
	 py = ynum
	endif
	
	pxvalue = xs + xd * px
	pyvalue = ys + yd * py
	
	
	pxw = {pxvalue-0.5*stepx,pxvalue+0.5*stepx,pxvalue+0.5*stepx,pxvalue-0.5*stepx,pxvalue-0.5*stepx}
	pyw = {pyvalue+0.5*stepy,pyvalue+0.5*stepy,pyvalue-0.5*stepy,pyvalue-0.5*stepy,pyvalue+0.5*stepy}
	
	wave/T sp = root:SpatialMapName
	SVAR fn = dfr:SML_filername
	
	fn = sp[px][py]
	
end



Function SML_showfilename_setvar(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	
End

 
 
 
 Function SML_DataLoadTmp()

	DFREF dfr = root:SpatialMapLoad
	SVAR  folderpath = dfr:SML_folderpath
	SVAR fn = dfr:SML_filername
	NVAR sesdatanum = dfr:SML_sesdatanum
	
	variable wnum=1
	string loadwn
	Do
		loadwn = "root:SpatialMapLoad:"+"loadmat"+num2str(wnum)
		if(waveexists($loadwn)==0)
			make/N=(100,100)/D/O $loadwn
		endif
		wnum+=1
	while (wnum<9)
	wave loadmat1 = dfr:loadmat1, loadmat2 = dfr:loadmat2, loadmat3 = dfr:loadmat3, loadmat4 = dfr:loadmat4
	wave loadmat5 = dfr:loadmat5, loadmat6 = dfr:loadmat6, loadmat7 = dfr:loadmat7, loadmat8 = dfr:loadmat8
		
	NVAR px = dfr:SML_px, py = dfr:SML_py
	variable ii=0,jj=0
	ii = px
	jj = py
	string dataname
	variable filenumber
	variable cond1, cond2, cond3, cond4

		cond1 = StringMatch(fn,"*.pxt")||StringMatch(fn,"*.pxp")
		cond2 = StringMatch(fn,"*.ibw")
		cond3 = StringMatch(fn,"*.txt")
		cond4 = StringMatch(fn,"*.krx")
		
		if (cond1==1)
		
			SML_SES2D(loadmat1,folderpath,fn,1)
			SML_SES2D(loadmat2,folderpath,fn,2)
			SML_SES2D(loadmat3,folderpath,fn,3)
			SML_SES2D(loadmat4,folderpath,fn,4)
			SML_SES2D(loadmat5,folderpath,fn,5)
			SML_SES2D(loadmat6,folderpath,fn,6)
			SML_SES2D(loadmat7,folderpath,fn,7)
			SML_SES2D(loadmat8,folderpath,fn,8)
						

		elseif((cond2==1))	

			SML_SESBinary(loadmat1,folderpath,fn,sesdatanum)
			
		elseif(cond3==1)
			SML_A1txt2D(loadmat1,folderpath,fn)
			
		elseif(cond4==1)
			SML_krxfile2D(loadmat1,folderpath,fn)

		endif
	
End


Function SML_button_showloadmat(ctrlName) : ButtonControl
	String ctrlName
	wave SpatialMap
	DFREF dfr = root:SpatialMapLoad
	NVAR sesdatanum=dfr:SML_sesdatanum

	Display;DelayUpdate

	String loadmatname = "loadmat" +num2str(sesdatanum)
	print loadmatname
	DFREF dfr = root:SpatialMapLoad
	wave loadmat = dfr:$loadmatname

	variable ndim = waveDims(loadmat)
	
	if (ndim==1)
		AppendToGraph loadmat
	elseif(ndim==2)
		AppendImage loadmat
		string iname = wavename("",0,1)
		ModifyImage $iname ctab= {*,*,Terrain256,0}
	//	ModifyGraph swapXY=1
	endif

End


Function SML_Choose_SES_Wave()

	DFREF dfr = root:SpatialMapLoad
	SVAR  folderpath = dfr:SML_folderpath
	SVAR filenamelist = dfr:SML_DataList
	NVAR sesdatanum=dfr:SML_sesdatanum

	String dataname = StringFromList(0, filenamelist,";")

	variable loaddatanum
	variable numinfolder
	string loadWaveName
	
	Newpath/O/Q pathtodata folderpath
	
	LOADDATA /p=pathtodata/q /T=load /L=1/O dataname
	setdatafolder root:load
	String wavenamelist = WAvelist("*",";","")	
	
	String message= "Thie data(ses) has multiple waves. Choose wave to map." 
	Prompt loaddatanum, message, popup, wavenamelist
	Doprompt "Choose wave", loaddatanum

 	if (V_flag==1)
 	 loaddatanum = 1
 	endif
	print loaddatanum, StringFromList((loaddatanum-1), wavenamelist)
	
	sesdatanum = loaddatanum
	setdatafolder root:
	
end

Function SML_Set_SESIgorMutiplewaveData()

	DFREF dfr = root:SpatialMapLoad
	SVAR  folderpath = dfr:SML_folderpath
	SVAR filenamelist = dfr:SML_DataList
	NVAR sesdatanum=dfr:SML_sesdatanum
	SVAR IgorWaveList=dfr:SML_IgorWaveList

	String dataname = StringFromList(0, filenamelist,";")
	
	variable cond = StringMatch(dataname,"*.pxt")||StringMatch(dataname,"*.pxp")


	variable loaddatanum
	variable numinfolder
	string loadWaveName
	
	if (cond==1)
	Newpath/O/Q pathtodata folderpath
	LOADDATA /p=pathtodata/q /T=load /L=1/O dataname
	setdatafolder root:load
	IgorWaveList = WAvelist("*",";","")	
	setdatafolder root:
	endif
	
end


Function SML_SetVar_setdatanum(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	DFREF dfr = root:SpatialMapLoad
	NVAR sesdatanum=dfr:SML_sesdatanum
	SVAR IgorWaveList=dfr:SML_IgorWaveList
	SVAR IgorNameItem  = dfr:SML_IgorNameItem

	sesdatanum = varNum
	IgorNameItem =  StringFromList((sesdatanum-1), IgorWaveList,";")
End

Function SML_CursorProc(s)
	STRUCT WMWinHookStruct &s

	DFREF dfr = root:SpatialMapLoad
	NVAR px = dfr:SML_px, py = dfr:SML_py

	strswitch( s.eventName )
		case "cursormoved":	
			if(cmpstr(s.cursorName,"G")==0)
			px = s.pointNumber
			py = s.ypointNumber
//		print px,py
//			print s.traceName, s.cursorName, s.pointNumber, s.ypointNumber
			SML_Update_cursor()
			SML_DataLoadTmp()
			endif
		break
	endswitch

	
End


Function [variable dimflag, string wavename0] SML_ReadDataTopWindow()

//	NVAR xs = dfr:SML_xstart, xstep = dfr:SML_xstep, xnum = dfr:SML_xnum
//	NVAR ys = dfr:SML_ystart, ystep = dfr:SML_ystep, ynum = dfr:SML_ynum
// 将来的に、map やprifileの中に、1D/2Dフラグ、座標情報、path情報、SESnum情報をnoteに書き込み
// windowを指定したときに、mapping macroのパラメーターを更新させる

	string traceList = TraceNameList("", ";", 1) 
	string imagelist = imageNameList("", ";") 
	string wn1
	variable index, itemnum
	

	if(itemsinlist(imagelist)==0)
		dimflag = 1
		itemnum = itemsinlist(traceList); index =0
		Do
			wn1=stringfromList(index,traceList)
			if(stringmatch(wn1,"*profile*")==1)
				break
			endif
			index+=1
			wn1 = ""
		while(index<itemnum)
		wavename0 = wn1
		
		
	elseif(itemsinlist(imagelist)>0)
		dimflag = 2
		itemnum = itemsinlist(imagelist); index =0
		Do
			wn1=stringfromList(index,imagelist)
			if(stringmatch(wn1,"*spatialmap*")==1)
				break
			endif
			index+=1
			wn1 = ""
		while(index<itemnum)
		wavename0 = wn1
	endif
	
	return [dimflag,wavename0]

End

function calling()
	string s1
	variable dim
	[dim,s1] = SML_ReadDataTopWindow()
	print dim,s1
	end