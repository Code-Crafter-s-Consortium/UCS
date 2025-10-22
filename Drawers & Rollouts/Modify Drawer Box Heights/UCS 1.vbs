;// Add's attributes to Cabinets for Drawer Height Adjustment
;//-----------------------------------------------------------------------------
;// PROGRAMMER: Patrick Hurst patrick@in-nova-tech.com
;//       DATE: 09/11/2024
;//	      LINK: https://nexus.hexagon.com/community/cabinet_vision/f/cv-user-created-standards/142099/ucs-to-modify-drawer-box-heights
;//
;//----------------------------------Notes---------------------------------------
;// Loops through an assemblies drawer openings and builds attributes according
;//
;//********************************** Implementation Notes *******************************************
;// If you build your drawers using standard heights. Enter your sizes @ line 126.
;//***************************************************************************************************

for each Cab assembly


;========================================================================================================
;// Exit Blocks
;// Exit if the cabinet is not a Base, Upper, Tall, or Vanity
;========================================================================================================
if (Cab.Class > 4) then
	exit
end if

;========================================================================================================
;// If the cabinet is not built with drawer stretchers, we use this value to calculate the opening heights
;//		from the drawer front heights.
;========================================================================================================
public U_CasePartThickness<meas> = 0.75 ;Case Part Thickness

;========================================================================================================
;// Loop to find if the cabinet contains drawers. if it does, create a parameter describing sizing method.
;// Will exit on finding the first drawer.
;// Flag for sizing method stored in _drawerConstType.
;// 0 = Fit using guide heights.
;// 1 = Standard Sizes
;========================================================================================================
_hasDrawers<bool> = false
i<text> = ''
while (i <= 6 & !_hasDrawers) do
	j<int> := 1
	while (Cab.Face{i}.DWR_OPEN@{j}.PID != null & !_hasDrawers) do
		if (Cab.Face{i}.DWR_OPEN@{j}.STYPE == 2) then
			_hasDrawers<bool> = true
			_drawerConstType<int> := Cab.Face{i}.DWR_OPEN@{j}._CB:1
			_economyDrawers<int> := Cab.Face{i}.DWR_OPEN@{j}._CS:U_Const_EconomyGrade
		end if
		j<int> += 1
	end while
	i<int> += 1
end while

;========================================================================================================
;// If there are no drawers, clean any previous parameters and exit.
;========================================================================================================
if (!this._hasDrawers) then
	i<text> = ''
	while (i <= 6) do
		j<int> := 1
		while (this.U_Face{i}_Drawer{j}Height != null) do
			delete U_Face{i}_Drawer{j}Height
			delete U_Face{i}_Drawer{j}_UID
			delete U_Face{i}_Opening{j}Height
			j<int> += 1
		end while
		i<int> += 1
	end while
	i<int> := 1
	while (U_Size{i} != null) do
		delete U_Size{i}
		i<int> += 1
	end while
	delete i
	delete j
	delete _hasDrawers
	delete _economyDrawers
	delete _drawerConstType
	delete U_DrawersEdit
	exit
end if

;========================================================================================================
;// Main editing attribute.
;========================================================================================================
if (U_DrawersEdit == null) then
	U_DrawersEdit<bool> = False
	U_DrawersEdit<style> = 1
	U_DrawersEdit<desc> = 'DWR.1 Modify Drawer Heights?'
end if

;========================================================================================================
;// If the main editing attribute is false, delete drawer attributes and exit.
;========================================================================================================
if (U_DrawersEdit == false) then
	i<text> = ''
	while (i <= 6) do
		j<int> := 1
		while (this.U_Face{i}_Drawer{j}Height != null) do
			delete U_Face{i}_Drawer{j}Height
			delete U_Face{i}_Drawer{j}_UID
			delete U_Face{i}_Opening{j}Height
			j<int> += 1
		end while
		i<int> += 1
	end while
	i<int> := 1
	while (U_Size{i} != null) do
		delete U_Size{i}
		i<int> += 1
	end while
	delete i
	delete j
	delete _hasDrawers
	delete _economyDrawers
	delete _drawerConstType
	exit
end if

;========================================================================================================
;// Enter standard drawer heights here.
;// If you use "Fit by Guide Clearance", you don't need to enter any sizes.
;// I use two different sets of sizes.
;========================================================================================================
if (_drawerConstType == 1) then
	if (this._economyDrawers == false | this._economyDrawers == null) then
		U_Size1<meas> := 2
		U_Size2<meas> := 3
		U_Size3<meas> := 4
		U_Size4<meas> := 5
		U_Size5<meas> := 6
		U_Size6<meas> := 7
		U_Size7<meas> := 8
		U_Size8<meas> := 10
		U_Size9<meas> := 11
	end if
	if (this._economyDrawers == true) then
		U_Size1<meas> := 4
		U_Size2<meas> := 6
		U_Size3<meas> := 8
	end if
end if

;========================================================================================================
;// The main loop where the attributes are actually built.
;// If we made it here, the cabinet has drawers, and the editing attribute is true
;//
;// Counters:
;// 	i <- counter per face, starts with text, then increments to 1: Face, Face1, Face2 ...
;//		j <- counter per drawer opening DWR_OPEN@1, DWR_OPEN@2 ...
;//		k <- counter per attribute, resets per face
;//		c <- counter per case opening, used when looping through case openings
;//		l <- counter to loop through standard sizes
;//
;// Attributes and Parameters:
;//		U_Face{i}_Drawer{k}Height   <- the value entered by the user
;//		U_Face{i}_Drawer{k}_UID		<- stores the PID of the DWR_OPEN to match against user entered value
;//		U_Face{i}_OpeningHeight{k}	<- the opening height that the DBOX sits in; used to calculate BTC
;//
;// Loop Structure:
;//
;// 	Loop Per Face (6 times)
;//			Loop Per Drawer in Face
;//				[Loop to find matching case opening]
;//				[Loop to build drop down size list]
;//			Loop to Cleanup Extra Attributes
;//
;// Section To Find Opening Height:
;// 	Face Frame:
;// 		Use the frame opening
;// 	Frameless:
;// 		Loop through case openings searching for one that
;//				matches within 2 inches
;//			Previously used PID but proved buggy:
;//				https://nexus.hexagon.com/community/cabinet_vision/f/cv-user-created-standards/38386/how-do-you-guys-associate-face-sections-with-their-interior-counterparts/258840
;// 		If it fails, try to calculate the opening height from the drawer front height.
;========================================================================================================
i<text> = ''
while (i <= 6) do
	j<int> := 1
	k<int> := 1
	while (Cab.Face{i}.DWR_OPEN@{j}.PID != null) do
		_drawer<text> = Cab.Face{i}.DWR_OPEN@{j}
		if ({_drawer}.Stype == 2) then
			if (cab.EURO  == 0 | cab.EURO == 3) then
				U_Face{i}_Opening{k}Height<meas> := {_drawer}.DY
			end if
			if (cab.EURO == 1 | cab.EURO == 2) then
				c<int> := 1
				_isFound<bool> = false
				while (Cab.Interior{i}.CO@{c}.PID != null & !_isFound) do
					_co<text> = Cab.Interior{i}.CO@{c}
					_isFound<bool> = (ABS({_drawer}.DX - {_co}.DX) < 2) & (ABS({_drawer}.DY - {_co}.DY) < 2) & (ABS({_drawer}.PABSX - {_co}.PABSX) < 2) & (ABS({_drawer}.PABSY - {_co}.PABSY) < 2)
					c<int> += 1
				end while
				c<int> -= 1
				if (_isFound) then
					U_Face{i}_Opening{k}Height<meas> := Cab.Interior{i}.CO@{c}.DY
				else
					if ((Cab.DY - {_drawer}.DY) == {_drawer}.PABSY | {_drawer}.Y == 0) then
						U_Face{i}_Opening{k}Height<meas> := {_drawer}.DY - Cab.U_CasePartThickness
					else 
						U_Face{i}_Opening{k}Height<meas> := {_drawer}.DY
					end if
				end if
			end if
			_label = {_drawer}.DBOX.DWR._Label
			_boxHeight<meas> := {_drawer}.BOXH
			if (this.U_Face{i}_Drawer{k}Height == null) then
				if (_drawerConstType == 1) then
					_listText<text> = '{_boxHeight} Inch = {_boxHeight}'
					l<int> := 1
					while (U_Size{l} < _boxHeight & U_Size{l} != null) do
						_size<meas> := U_Size{l}
						_listText = '{_listText}|{_size} Inch = {_size}'
						l<int> += 1
					end while
					U_Face{i}_Drawer{k}Height<meas> = '<Lst>{_listText}'
				end if
				if (_drawerConstType == 0) then
					U_Face{i}_Drawer{k}Height<meas> := _boxHeight
				end if
				U_Face{i}_Drawer{k}Height<style> = 1
				U_Face{i}_Drawer{k}Height<desc> = 'DWR.2 Face {i} Drawer {_label} Height'
				U_Face{i}_Drawer{k}_UID<int> := {_drawer}.PID
			end if
			k<int> += 1
		end if
		j<int> += 1
	end while	
	while (U_Face{i}_Drawer{k}Height != null) do	
		delete U_Face{i}_Drawer{k}Height
		delete U_Face{i}_Drawer{k}_UID
		delete U_Face{i}_Opening{k}Height
		k<int> += 1
	end while
	i<int> += 1
end while

;========================================================================================================
;// Clean up parameters.
;========================================================================================================
delete c
delete i
delete j
delete k
delete l
delete _drawer
delete _co
delete _boxHeight
delete _listText
delete _label
delete _size
delete _economyDrawers
delete _hasDrawers
delete _drawerConstType