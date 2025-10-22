;//Add adjustments to drawer openings to control drawer heights
;//-----------------------------------------------------------------------------
;//PROGRAMMER: Patrick Hurst patrick@in-nova-tech.com
;//      DATE: 09/12/2024
;//	     LINK: https://nexus.hexagon.com/community/cabinet_vision/f/cv-user-created-standards/142099/ucs-to-modify-drawer-box-heights
;//----------------------------------Notes---------------------------------------
;//See Notes from UCS 'Drawer Heights.1 Cabinet Attributes (Multiple Faces)'

for each DWR_OPEN Part

;========================================================================================================
;// Exit Blocks
;// Exit if the cabinet is not a Base, Upper, Tall, or Vanity
;// If the drawer editing attribute on the main cabinet is set to false, then delete any clearance
;// 	parameters and exit.
;========================================================================================================
if (Cab.Class > 4) then
	exit
end if
if (Cab.U_DrawersEdit == false) then
	delete BTC
	exit
end if

;========================================================================================================
;// Loop matches the attribute to the drawer.
;// U_Face{i}_Drawer{j}_UID was saved with the PID of the drawer being edited. Loop until the PID matches,
;// 	Record i and j into k and l and break out of the loop.
;========================================================================================================
i<text> = ''
l<int> := 0
k<text> = ''
while (i <= 6 & l == 0) do
	j<int> := 1
	while (Cab.U_Face{i}_Drawer{j}Height != null & l == 0) do
		if (Cab.U_Face{i}_Drawer{j}_UID == this.PID) then
			k<text> = '{i}'
			l<int> := j
		end if
		j<int> += 1
	end while
	i<int> += 1
end while
if (l == 0) then
	exit
end if

;========================================================================================================
;// The line of code that actually does something ☺. Set the top clearance to be the opening height,
;// 	minus the user entered value, minus the bottom clearnace.
;========================================================================================================
BTC := U_Face{k}_Opening{l}Height - Cab.U_Face{k}_Drawer{l}Height - this.DG._M:MBB

;========================================================================================================
;// Clean up.
;========================================================================================================
delete i
delete j
delete k
delete l