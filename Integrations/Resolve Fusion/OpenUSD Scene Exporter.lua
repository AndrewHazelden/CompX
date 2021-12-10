_VERSION = 'v5 2021-12-10'
--[[--
----------------------------------------------------------------------------
Kartaverse - OpenUSD Scene Exporter - v5 2021-12-10 04.42 PM
by Andrew Hazelden
www.andrewhazelden.com
andrew@andrewhazelden.com


Overview
---------
The "OpenUSD Scene Exporter" script allows you to export  PIXAR USD ASCII (.usda) data, along with Maya ASCII 2019 (.ma), Maya MOVE ASCII (.mov), XYZ ASCII (.xyz), and PLY ASCII (.ply) format data.


Scenegraph Export Options
--------------------------
AlembicMesh3D nodes can be exported to the PIXAR USD ASCII (.usda), Maya ASCII 2019 (.ma), and Maya MOVE ASCII (.mov) format.

Camera3D nodes with per-frame Keyframe animated XYZ translation/rotation keys can be exported to the PIXAR USD ASCII (.usda), and Maya MOVE ASCII (.mov) format.

PointCloud3D node based points or FBXMesh3D node OBJ mesh vertices can be exported to XYZ ASCII (.xyz), and PLY ASCII (.ply) formats. 

Static (non-animated) Camera3D nodes can be exported to the Maya ASCII 2019 (.ma) format. 

Keyframe animated FBXMesh3D nodes with per-frame XYZ translation/rotation keys can be exported to the Maya MOVE ASCII (.mov) format. 

The "OpenUSD Scene Exporter.lua" comp/tool script works in Fusion v9-17.4.2+ and Resolve v15-17.4.2+. 


Easy Installation:
-------------------

The "OpenUSD Scene Exporter.lua" script is typically installed in a single click using the "Reactor" Package Manager by adding the AtomTestLab add-on repository, and then selecting the "Kartaverse/CompX/Scripts | Virtual Production" atom package.

https://gitlab.com/AndrewHazelden/AtomTestLab

Manual Installation:

Step 1. If you are unable to use Reactor to download and install the "Kartaverse/CompX/Scripts | Virtual Production" atom package, you can always download the most recent version of the "OpenUSD Scene Exporter.lua" script directly from the CompX GitHub Repository at:

https://github.com/AndrewHazelden/CompX/


Step 2. Copy the downloaded "OpenUSD Scene Exporter.lua" script to your Fusion/Resolve Fusion page user preferences' "Tool" and "Comp" based "Scripts:/"  PathMap locations at:

	Scripts:/Tool/Kartaverse/CompX/
	Scripts:/Comp/Kartaverse/CompX/

*Note: You will need to create these sub-folders by hand since they won't pre-exist on a manual install.

Fusion Standalone Manual Script Install:
	On Windows this works out to:
		%AppData%\Blackmagic Design\Fusion\Scripts\Comp\Kartaverse\CompX\
		%AppData%\Blackmagic Design\Fusion\Scripts\Tool\Kartaverse\CompX\

	On Linux this works out to:
		$HOME/.fusion/BlackmagicDesign/Fusion/Scripts/Comp/Kartaverse/CompX/
		$HOME/.fusion/BlackmagicDesign/Fusion/Scripts/Tool/Kartaverse/CompX/

	On MacOS this works out to:
		$HOME/Library/Application Support/Blackmagic Design/Fusion/Scripts/Comp/Kartaverse/CompX/
		$HOME/Library/Application Support/Blackmagic Design/Fusion/Scripts/Tool/Kartaverse/CompX/


Resolve Fusion Page Manual Script Install:
	On Windows this works out to:
		%AppData%\Blackmagic Design\DaVinci Resolve\Fusion\Scripts\Comp\Kartaverse\CompX\
		%AppData%\Blackmagic Design\DaVinci Resolve\Fusion\Scripts\Tool\Kartaverse\CompX\

	On Linux this works out to:
		$HOME/.fusion/BlackmagicDesign/DaVinci Resolve/Fusion/Scripts/Comp/Kartaverse/CompX/
		$HOME/.fusion/BlackmagicDesign/DaVinci Resolve/Fusion/Scripts/Tool/Kartaverse/CompX/

	On MacOS this works out to:
		$HOME/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/Comp/Kartaverse/CompX/
		$HOME/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/Tool/Kartaverse/CompX/

Usage:
Step 1. Save your Fusion composite to disk.

Step 2. Select a single PointCloud3D, FBXMesh3D (OBJ mesh), AlembicMesh3D, or Camera3D node in the Flow/Nodes view.

Step 3. Run the "Script > Kartaverse > CompX > OpenUSD Scene Exporter" menu item. The point cloud, mesh, or camera data will be saved to disk.


Notes:
- If you are exporting a Maya ASCII (.ma) point cloud you may way to adjust the Maya Locator Size "SpinBox" control to change the visible locator scale in the Maya scene file. Common values you might explore are "0.1" or "0.05" if you are working with centimetre/decimetre units as your scene size in Maya.

- The Maya ASCII (.ma) exported AlembicMesh3D data is loaded in the .ma file as an "Alembic Reference Import" which works well if the ABC meshes have not been moved from their initial XYZ position in the Fusion comp.

- The "Maya MOVE ASCII (.mov)" export format saves out an ASCII file that records 1 set of XYZ Translation and Rotation keyframe animation data per line of the text file. The Maya MOVE format is a very minimal data format that can be viewed in a spreadsheet. It is simply a space or tab delimited file with the raw keyframe export of an object's transform data.

- Fusion v9 appears to only support the Alembic HDF5 "legacy" (pre-Maya 2014 Extension 1) era .abc mesh format. Newer Ogawa formatted abc files fail to load in my tests. This means you need to have compiled PIXAR's open source "usdview" or your USD for Maya/Katana/Houdini/etc... plugins with HDF5 support enabled if you want to interact with Fusion compatible Alembic files in an exported USD ASCII "Reference Assembly".

Todo:
- Save/Attempt to restore an extra "comp" scope preference for the 'CompX.OpenUSDSceneExporter.ExportDirectory' setting so each comp can restore the last output folder used for that individual project. If this comp scope setting doesn't exist then use the last global scope preference.

- For Maya ASCII 2019 (.ma) "Alembic Reference Import" mode .ma settings check if Maya's relative workspace option can be used with the exported filepath for the Alembic references, then look at adding an control to define the current Maya Workspace/"File > Set Project" value in the OpenUSD Scene Exporter script UI so Maya exported relative .abc filepaths to stay relative.

----------------------------------------------------------------------------
--]]--

------------------------------------------------------------------------

------------------------------------------------------------------------
-- Maya ASCII Export Settings:
-- Size of a Maya ASCII (.ma) locator (0.05, 0.1, and 0.2 are common values)
local mayaLocatorSize = 0.2

-- Are the Maya camera attributes animated (true/false)
local mayaAnimatedCamera = false


------------------------------------------------------------------------
-- Pixar USD ASCII Export Settings:
-- USD ASCII scene scale = CM
local metersPerUnit = 0.01

-- Maya default style Y-axis Up-coordinate system
local upAxis = 'Y'

-- Are the PIAR USD ASCII camera attributes animated (true/false)
local usdAnimatedCamera = true


------------------------------------------------------------------------
-- Find out the current operating system platform.
-- The platform local variable should be set to either "Windows", "Mac", or "Linux".
local platform = (FuPLATFORM_WINDOWS and 'Windows') or (FuPLATFORM_MAC and 'Mac') or (FuPLATFORM_LINUX and 'Linux')

------------------------------------------------------------------------
-- Add the platform specific folder slash character
osSeparator = package.config:sub(1,1)

------------------------------------------------------------------------
-- Home Folder
-- Add the user folder path - Example: C:\Users\Administrator\
if platform == 'Windows' then
	homeFolder = tostring(os.getenv('USERPROFILE')) .. osSeparator
else
	-- Mac and Linux
	homeFolder = tostring(os.getenv('HOME')) .. osSeparator
end

------------------------------------------------------------------------
-- Set a fusion specific preference value
-- Example: SetPreferenceData('Kartaverse.Version', '1.0', true)
function SetPreferenceData(pref, value, status)
	-- comp:SetData(pref, value)
	fusion:SetData(pref, value)

	-- List the preference value
	if status == 1 or status == true then
		if value == nil then
			print('[Setting ' .. pref .. ' Preference Data] ' .. 'nil')
		else
			print('[Setting ' .. pref .. ' Preference Data] ' .. value)
		end
	end
end

------------------------------------------------------------------------
-- Read a fusion specific preference value. If nothing exists set and return a default value
-- Example: GetPreferenceData('Kartaverse.Version', 1.0, true)
function GetPreferenceData(pref, defaultValue, status)
	-- local newPreference = comp:GetData(pref)
	local newPreference = fusion:GetData(pref)
	if newPreference then
		-- List the existing preference value
		if status == 1 or status == true then
			if newPreference == nil then
				print('[Reading ' .. pref .. ' Preference Data] ' .. 'nil')
			else
				print('[Reading ' .. pref .. ' Preference Data] ' .. newPreference)
			end
		end
	else
		-- Force a default value into the preference & then list it
		newPreference = defaultValue
		-- comp:SetData(pref, defaultValue)
		fusion:SetData(pref, defaultValue)

		if status == 1 or status == true then
			if newPreference == nil then
				print('[Creating ' .. pref .. ' Preference Data] ' .. 'nil')
			else
				print('[Creating '.. pref .. ' Preference Entry] ' .. newPreference)
			end
		end
	end

	return newPreference
end

------------------------------------------------------------------------
-- Add a slash to the end of folder paths
function ValidateDirectoryPath(path)
	if string.sub(path, -1, -1) ~= osSeparator then
		path = path .. osSeparator
	end

	return path
end

------------------------------------------------------------------------
-- Find out the current directory from a file path
-- Example: print(Dirname('/Volumes/Media/pointcloud.xyz'))
function Dirname(mediaDirName)
	return mediaDirName:match('(.*' .. osSeparator .. ')')
end

------------------------------------------------------------------------
-- Open a folder window up using your desktop file browser
-- Example: openDirectory('/Volumes/Media/')
function openDirectory(mediaDirName)
	command = nil
	dir = Dirname(mediaDirName)

	if platform == 'Windows' then
		-- Running on Windows
		command = 'explorer "' .. dir .. '"'

		print('[Launch Command] ', command)
		os.execute(command)
	elseif platform == 'Mac' then
		-- Running on Mac
		command = 'open "' .. dir .. '" &'

		print('[Launch Command] ', command)
		os.execute(command)
	elseif platform == 'Linux' then
		-- Running on Linux
		command = 'nautilus "' .. dir .. '" &'

		print('[Launch Command] ', command)
		os.execute(command)
	else
		print('[Platform] ', platform)
		print('There is an invalid platform defined in the local platform variable at the top of the code.')
	end
end

-- Add duplicate slashes for Windows Filepaths in a Maya ASCII file
function DupSlashes(path)
	path = string.gsub(path, [[\]], [[\\]])
	return path
end

------------------------------------------------------------------------
-- Show the UI manager GUI
function OpenUSDSceneExporterWin()
	-- Load UI Manager
	ui = app.UIManager
	disp = bmd.UIDispatcher(ui)

	-- Read the open Fusion composite's name (In the Resolve Fusion page this is an empty string...)
	local compFile = tostring(comp:GetAttrs().COMPS_FileName)
	print('[Fusion Comp Source File] ' .. tostring(compFile))

	-- Read the last folder accessed from a ExportDirectory preference
	-- The default value for the first time the RequestDir is shown in the "$HOME/Documents/" folder.
	local exportDirectory = GetPreferenceData('CompX.OpenUSDSceneExporter.ExportDirectory', homeFolder, false)
	
	-- Maya Locator Size
	local mayaLocatorSize = GetPreferenceData('CompX.OpenUSDSceneExporter.MayaLocatorSize', mayaLocatorSize, false)

	-- Load the Reactor icon resources PathMap
	local iconsDir = fusion:MapPath('Reactor:/System/UI/Images') .. 'icons.zip/'
	-- print('[Icons Folder] ' .. tostring(iconsDir))

	-- Create a list of the standard PNG format ui:Icon/ui:Button Sizes/MinimumSizes in px
	local tiny = 14
	local small = 16
	local medium = 24
	local large = 32
	local long = 110
	local big = 150

	-- Create Lua tables with X/Y defined Icon Sizes
	local iconsMedium = {large,large}
	local iconsMediumLong = {big,large}

	-- Track the current node selection
	local selectedNode = comp.ActiveTool
	local selectedNodeName = ''
	
	if selectedNode then
		selectedNodeName = selectedNode.Name
	end 
	------------------------------------------------------------------------
	-- Create the new window
	local epcwin = disp:AddWindow({
		ID = 'OpenUSDSceneExporter',
		TargetID = 'OpenUSDSceneExporter',
		WindowTitle = 'OpenUSD Scene Exporter',
		Geometry = {200,100,600,155},
		MinimumSize = {600, 140},
		-- Spacing = 10,
		-- Margin = 20,

		ui:VGroup{
			ID = 'root',
			
			ui:HGroup{
				Weight = 0.01,
				ui:Label{
					ID = 'FormatLabel',
					Weight = 0.1,
					Text = 'Export Format',
				},
				ui:ComboBox{
					ID = 'FormatCombo',
				},
				ui:Label{
					ID = 'NodeLabel',
					Weight = 0.2,
					Text = 'Selected Node',
				},
				ui:LineEdit{
					ID = 'NodeNameText',
					PlaceholderText = '[Select a Fusion 3D Node]',
					Text = selectedNodeName,
					ReadOnly = true,
				},
			},

			-- pointcloud Working Directory
			ui:HGroup{
				Weight = 0.01,
				ui:Label{
					ID = 'ExportDirectoryLabel',
					Weight = 0.2,
					Text = 'Export Directory',
				},
				ui:HGroup{
					ui:LineEdit{
						ID = 'ExportDirectoryText',
						PlaceholderText = '',
						Text = exportDirectory,
					},
					ui:Button{
						ID = 'SelectFolderButton',
						Weight = 0.01,
						Text = 'Select Folder',
						IconSize = iconsMedium,
						Icon = ui:Icon{
							File = iconsDir .. 'folder.png'
						},
						MinimumSize = iconsMediumLong,
						Flat = true,
					},
				},
			},

			ui:VGap(5),

			ui:HGroup{
				Weight = 0,
				ui:Label{
					ID = 'MayaLocatorSizeLabel',
					Weight = 0.2,
					Text = 'Maya Locator Size',
				},
				ui:DoubleSpinBox{
					ID = 'MayaLocatorSizeSpinner',
					Value = mayaLocatorSize,
					-- Value = 0.05,
					Maximum = 1000,
					Minimum = 0.001,
					StepBy = 0.1,
					SingleStep = 0.1,
				},
				ui:HGap(150),
			},
			
			ui:HGroup{
				Weight = 0.01,
				ui:Button{
					ID = 'CancelButton',
					Text = 'Cancel',
					IconSize = iconsMedium,
					Icon = ui:Icon{
						File = iconsDir .. 'close.png'
					},
					MinimumSize = iconsMedium,
					Flat = true,
				},
				-- ui:HGap(20),
				ui:HGap(150),
				ui:Button{
					ID = 'ContinueButton',
					Text = 'Continue',
					IconSize = iconsMedium,
					Icon = ui:Icon{
						File = iconsDir .. 'create.png'
					},
					MinimumSize = iconsMedium,
					Flat = true,
				},
			},
		}
	})

	-- Add your GUI element based event functions here:
	local epcitm = epcwin:GetItems()

	-- The window was closed
	function epcwin.On.OpenUSDSceneExporter.Close(ev)
		epcwin:Hide()

		pointcloudFile = nil
		pointcloudData = nil

		disp:ExitLoop()
	end

	-- The Continue Button was clicked
	function epcwin.On.ContinueButton.Clicked(ev)
		-- Maya Locator size:
		mayaLocatorSize = epcitm.MayaLocatorSizeSpinner.Value

		-- Read the render time frame ranges
		startFrameGlobal = comp:GetAttrs().COMPN_GlobalStart
		endFrameGlobal = comp:GetAttrs().COMPN_GlobalEnd
		
		startFrame = comp:GetAttrs().COMPN_RenderStart
		endFrame = comp:GetAttrs().COMPN_RenderEnd
		renderStep = comp:GetAttrs().COMPI_RenderStep

		-- Read the Working Directory textfield
		workingDir = ValidateDirectoryPath(epcitm.ExportDirectoryText.Text)

		if workingDir == nil then
			-- Check if the working directory is empty
			print('[Working Directory] The textfield is empty!')
		else
			if bmd.fileexists(workingDir) == false then
				-- Create the working directory if it doesn't exist yet
				print('[Working Directory] Creating the folder: "' .. workingDir .. '"')
				bmd.createdir(workingDir)
			end

			-- Build the point cloud folder path
			pointcloudFolder = fusion:MapPath(workingDir .. osSeparator)

			-- Remove double slashes from the path
			pointcloudFolder = string.gsub(pointcloudFolder, '//', '/')
			pointcloudFolder = string.gsub(pointcloudFolder, '\\\\', '\\')

			-- Create the point cloud output folder
			bmd.createdir(pointcloudFolder)
			if bmd.fileexists(pointcloudFolder) == false then
				-- See if there was an error creating the pointcloud folder
				print('[pointcloud Folder] Error creating the folder: "' .. pointcloudFolder .. '".\nPlease select an export directory with write permissions.')
				disp:ExitLoop()
			else
				-- Success
				epcwin:Hide()

				-- Save a default ExportDirectory preference
				SetPreferenceData('CompX.OpenUSDSceneExporter.ExportDirectory', workingDir, false)

				-- Save the point cloud format
				SetPreferenceData('CompX.OpenUSDSceneExporter.PointCloudFormat', epcitm.FormatCombo.CurrentIndex, false)

				-- Save the Maya Locator Size Gui setting
				SetPreferenceData('CompX.OpenUSDSceneExporter.MayaLocatorSize', mayaLocatorSize, false)

				-- List the selected Node in Fusion
				selectedNode = comp.ActiveTool
				if selectedNode then
					local nodeName = selectedNode.Name
					print('[Selected Node] ' .. tostring(nodeName))

					toolAttrs = selectedNode:GetAttrs()
					nodeType = toolAttrs.TOOLS_RegID

					-- Get the point cloud export format: "xyz", "ply", or "ma"
					local exportFormat = epcitm.FormatCombo.CurrentText
					local fileExt = ''
					if exportFormat == 'XYZ ASCII (.xyz)' then
						fileExt = 'xyz'
					elseif exportFormat == 'PLY ASCII (.ply)' then
						fileExt = 'ply'
					elseif exportFormat == 'Maya ASCII (.ma)' then
						fileExt = 'ma'
					elseif exportFormat == 'Maya MOVE ASCII (.mov)' then
						fileExt = 'mov'
					elseif exportFormat == 'PIXAR USDA ASCII (.usda)' then
						fileExt = 'usda'
					else
						fileExt = 'xyz'
					end

					-- Use the Export Directory from the UI Manager GUI
					outputDirectory = pointcloudFolder
					os.execute('mkdir "' .. outputDirectory ..'"')

					-- Save a copy of the point cloud to the $TEMP/Kartaverse/ folder
					pointcloudFile = outputDirectory .. nodeName .. '.' .. fileExt
					print('[Export Format] "' .. tostring(exportFormat) .. '"')

					-- Read data from the selected node
					if nodeType == 'Camera3D' then
						-- Read the Camera3D node settings

						-- Lens focal length (in mm)
						focalLength = selectedNode:GetInput('FLength')

						-- Lens focus distance (in scene units)
						focusDistance = selectedNode:GetInput('PlaneOfFocus')

						-- f-Stop is a fixed (default) value that is not used inside of Fusion's Camera3D node
						fStop = 5.6

						apertureW = selectedNode:GetInput('ApertureW')
						apertureH = selectedNode:GetInput('ApertureH')

						lensShiftX = selectedNode:GetInput('LensShiftX')
						lensShiftY = selectedNode:GetInput('LensShiftY')

						perspNearClip = selectedNode:GetInput('PerspNearClip')
						perspFarClip = selectedNode:GetInput('PerspFarClip')

						-- Translate
						tx = selectedNode:GetInput('Transform3DOp.Translate.X')
						ty = selectedNode:GetInput('Transform3DOp.Translate.Y')
						tz = selectedNode:GetInput('Transform3DOp.Translate.Z')

						-- Rotate
						rx = selectedNode:GetInput('Transform3DOp.Rotate.X')
						ry = selectedNode:GetInput('Transform3DOp.Rotate.Y')
						rz = selectedNode:GetInput('Transform3DOp.Rotate.Z')

						-- Scale
						sx = selectedNode:GetInput('Transform3DOp.Scale.X')
						sy = selectedNode:GetInput('Transform3DOp.Scale.Y')
						sz = selectedNode:GetInput('Transform3DOp.Scale.Z')

						-- Results
						print('\t[Focal Length (mm)] ' .. tostring(focalLength))
						print('\t[Camera Aperture (in)] ' .. tostring(apertureW) .. ' x ' .. tostring(apertureH))
						print('\t[Focus Distance (scene units)] ' .. tostring(focusDistance))
						print('\t[Lens Shift] ' .. tostring(lensShiftX) .. ' x ' .. tostring(lensShiftY))
						print('\t[Near Clip] ' .. tostring(perspNearClip))
						print('\t[Far Clip] ' .. tostring(perspFarClip))
						print('\t[Translate] [X] ' .. tx .. ' [Y] ' .. ty .. ' [Z] ' .. tz)
						print('\t[Rotate] [X] ' .. rx .. ' [Y] ' .. ry .. ' [Z] ' .. rz)
						print('\t[Scale] [X] ' .. sx .. ' [Y] ' .. sy .. ' [Z] ' .. sz)

						
						if fileExt == 'ma' then
							-- Maya ASCII (.ma) export
							-- The system temporary directory path (Example: $TEMP/Kartaverse/)
							-- outputDirectory = comp:MapPath('Temp:\\Kartaverse\\')

							-- Open up the file pointer for the output textfile
							outFile, err = io.open(pointcloudFile,'w')
							if err then
								print('[Camera] [Error opening file for writing] ' .. tostring(pointcloudFile))
								disp:ExitLoop()
							end

							-- Write a Maya ASCII header entry
							outFile:write('//Maya ASCII scene\n')
							outFile:write('//Name: ' .. tostring(nodeName) .. '.' .. tostring(fileExt) .. '\n') 
							outFile:write('//Created by Kartaverse/CompX : ' ..  _VERSION .. '\n')
							outFile:write('//Created: ' .. tostring(os.date('%Y-%m-%d %I:%M:%S %p')) .. '\n')
							outFile:write('requires maya "2019";\n')
							outFile:write('currentUnit -l centimeter -a degree -t film;\n')
							outFile:write('fileInfo "application" "maya";\n')
							outFile:write('createNode transform -s -n "persp";\n')
							outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n')
							outFile:write('\tsetAttr ".v" no;\n')
							outFile:write('\tsetAttr ".t" -type "double3" 42.542190019936143 11.856220346068302 7.6545481521220538 ;\n')
							outFile:write('\tsetAttr ".r" -type "double3" -15.338352729601354 79.799999999999187 8.9803183372077805e-15 ;\n')
							outFile:write('createNode camera -s -n "perspShape" -p "persp";\n')
							outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n')
							outFile:write('\tsetAttr -k off ".v" no;\n')
							outFile:write('\tsetAttr ".fl" 34.999999999999986;\n')
							outFile:write('\tsetAttr ".coi" 44.82186966202994;\n')
							outFile:write('\tsetAttr ".imn" -type "string" "persp";\n')
							outFile:write('\tsetAttr ".den" -type "string" "persp_depth";\n')
							outFile:write('\tsetAttr ".man" -type "string" "persp_mask";\n')
							outFile:write('\tsetAttr ".hc" -type "string" "viewSet -p %camera";\n')

							-- Write out the Camera3D node data
							outFile:write('createNode transform -n "' .. tostring(nodeName) .. '";\n')
							outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n')
							-- Visible (Yes)
							outFile:write('\tsetAttr ".v";\n')
							-- Translate XYZ
							outFile:write('\tsetAttr ".t" -type "double3" ' .. tx .. ' ' .. ty .. ' ' .. tz .. ';\n')
							-- Rotate XYZ
							outFile:write('\tsetAttr ".r" -type "double3" ' .. rx .. ' ' .. ry .. ' ' .. rz .. ';\n')

							outFile:write('createNode camera -s -n "' .. tostring(nodeName) .. 'Shape" -p "' .. tostring(nodeName) .. '";\n')
							outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n')
							outFile:write('\tsetAttr -k off ".v";\n')

							-- Lens Focal length (mm)
							outFile:write('\tsetAttr ".fl" ' .. tostring(focalLength) .. ';\n')

							-- Camera Aperture (inches)
							outFile:write('\tsetAttr ".cap" -type "double2" ' .. tostring(apertureW) .. ' ' .. tostring(apertureH) .. ';\n')

							-- Film Offset
							outFile:write('\tsetAttr ".fio" -type "double2" ' .. tostring(lensShiftX) .. ' ' .. tostring(lensShiftY) .. ';\n')

							outFile:write('\tsetAttr ".coi" 44.82186966202994;\n')
							outFile:write('\tsetAttr ".imn" -type "string" "' .. tostring(nodeName) .. '";\n')
							outFile:write('\tsetAttr ".den" -type "string" "' .. tostring(nodeName) .. '_depth";\n')
							outFile:write('\tsetAttr ".man" -type "string" "' .. tostring(nodeName) .. '_mask";\n')
							outFile:write('\tsetAttr ".hc" -type "string" "viewSet -p %camera";\n')

							-- Should the Maya camera export be animated
							if mayaAnimatedCamera == true then
								local tx_animated = ''
								local ty_animated = ''
								local tz_animated = ''

								local rx_animated = ''
								local ry_animated = ''
								local rz_animated = ''
								
								local sx_animated = ''
								local sy_animated = ''
								local sz_animated = ''

								total_keyframes = 0

								-- Step through the timeline at the comp's "StepBy" interval
								for frame = startFrame, endFrame, renderStep do
									-- Animated camera parameters
									focalLength = selectedNode:GetInput('FLength', frame)
									print('\t[Focal Length (mm)] ' .. tostring(focalLength))

									apertureW = selectedNode:GetInput('ApertureW', frame)
									apertureH = selectedNode:GetInput('ApertureH', frame)
									print('\t[Camera Aperture (in)] ' .. tostring(apertureW) .. ' x ' .. tostring(apertureH))

									lensShiftX = selectedNode:GetInput('LensShiftX', frame)
									lensShiftY = selectedNode:GetInput('LensShiftY', frame)
									print('\t[Lens Shift] ' .. tostring(lensShiftX) .. ' x ' .. tostring(lensShiftY))

									perspNearClip = selectedNode:GetInput('PerspNearClip', frame)
									print('\t[Near Clip] ' .. tostring(perspNearClip))

									perspFarClip = selectedNode:GetInput('PerspFarClip', frame)
									print('\t[Far Clip] ' .. tostring(perspFarClip))

									tx = selectedNode:GetInput('Transform3DOp.Translate.X', frame)
									ty = selectedNode:GetInput('Transform3DOp.Translate.Y', frame)
									tz = selectedNode:GetInput('Transform3DOp.Translate.Z', frame)
									print('\t[Translate] [X] ' .. tx .. ' [Y] ' .. ty .. ' [Z] ' .. tz)

									rx = selectedNode:GetInput('Transform3DOp.Rotate.X', frame)
									ry = selectedNode:GetInput('Transform3DOp.Rotate.Y', frame)
									rz = selectedNode:GetInput('Transform3DOp.Rotate.Z', frame)
									print('\t[Rotate] [X] ' .. rx .. ' [Y] ' .. ry .. ' [Z] ' .. rz)

									sx = selectedNode:GetInput('Transform3DOp.Scale.X', frame)
									sy = selectedNode:GetInput('Transform3DOp.Scale.Y', frame)
									sz = selectedNode:GetInput('Transform3DOp.Scale.Z', frame)
									print('\t[Scale] [X] ' .. sx .. ' [Y] ' .. sy .. ' [Z] ' .. sz)

									-- Append the per frame animated keys
									tx_animated = tx_animated .. tostring(frame) .. ' ' .. tx .. ' '
									ty_animated = ty_animated .. tostring(frame) .. ' ' .. ty .. ' '
									tz_animated = tz_animated .. tostring(frame) .. ' ' .. tz .. ' '

									rx_animated = rx_animated .. tostring(frame) .. ' ' .. rx .. ' '
									ry_animated = ry_animated .. tostring(frame) .. ' ' .. ry .. ' '
									rz_animated = rz_animated .. tostring(frame) .. ' ' .. rz .. ' '

									sx_animated = sx_animated .. tostring(frame) .. ' ' .. sx .. ' '
									sy_animated = sy_animated .. tostring(frame) .. ' ' .. sy .. ' '
									sz_animated = sz_animated .. tostring(frame) .. ' ' .. sz .. ' '

									total_keyframes = total_keyframes + 1
								end

								print('[TX Keys] ' .. tx_animated)
								print('[TY Keys] ' .. ty_animated)
								print('[TZ Keys] ' .. tz_animated)
								print('\n')

								print('[RX Keys] ' .. rx_animated)
								print('[RY Keys] ' .. ry_animated)
								print('[RZ Keys] ' .. rz_animated)
								print('\n')

								-- Add the animation curves
								-- translateX
								outFile:write('createNode animCurveTL -n "' .. tostring(nodeName) .. '_translateX";\n') 
								outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n') 
								outFile:write('\tsetAttr ".tan" 2;\n') 
								outFile:write('\tsetAttr ".wgt" no;\n') 
								outFile:write('\tsetAttr -s ' .. tostring(total_keyframes) .. ' ".ktv[0:' .. tostring(total_keyframes - 1) .. ']"  ' .. tx_animated .. ';\n')
								-- translateY
								outFile:write('createNode animCurveTL -n "' .. tostring(nodeName) .. '_translateY";\n') 
								outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n') 
								outFile:write('\tsetAttr ".tan" 2;\n') 
								outFile:write('\tsetAttr ".wgt" no;\n') 
								outFile:write('\tsetAttr -s ' .. tostring(total_keyframes) .. ' ".ktv[0:' .. tostring(total_keyframes - 1) .. ']"  ' .. ty_animated .. ';\n')
								-- translateY
								outFile:write('createNode animCurveTL -n "' .. tostring(nodeName) .. '_translateZ";\n') 
								outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n') 
								outFile:write('\tsetAttr ".tan" 2;\n') 
								outFile:write('\tsetAttr ".wgt" no;\n') 
								outFile:write('\tsetAttr -s ' .. tostring(total_keyframes) .. ' ".ktv[0:' .. tostring(total_keyframes - 1) .. ']"  ' .. tz_animated .. ';\n')

								-- rotateX
								outFile:write('createNode animCurveTL -n "' .. tostring(nodeName) .. '_rotateX";\n') 
								outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n') 
								outFile:write('\tsetAttr ".tan" 2;\n') 
								outFile:write('\tsetAttr ".wgt" no;\n') 
								outFile:write('\tsetAttr -s ' .. tostring(total_keyframes) .. ' ".ktv[0:' .. tostring(total_keyframes - 1) .. ']"  ' .. rx_animated .. ';\n')
								-- rotateY
								outFile:write('createNode animCurveTL -n "' .. tostring(nodeName) .. '_rotateY";\n') 
								outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n') 
								outFile:write('\tsetAttr ".tan" 2;\n') 
								outFile:write('\tsetAttr ".wgt" no;\n') 
								outFile:write('\tsetAttr -s ' .. tostring(total_keyframes) .. ' ".ktv[0:' .. tostring(total_keyframes - 1) .. ']"  ' .. ry_animated .. ';\n')
								-- rotateZ
								outFile:write('createNode animCurveTL -n "' .. tostring(nodeName) .. '_rotateZ";\n') 
								outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n') 
								outFile:write('\tsetAttr ".tan" 2;\n') 
								outFile:write('\tsetAttr ".wgt" no;\n') 
								outFile:write('\tsetAttr -s ' .. tostring(total_keyframes) .. ' ".ktv[0:' .. tostring(total_keyframes - 1) .. ']"  ' .. rz_animated .. ';\n')
--								
--								-- scaleX
--								outFile:write('createNode animCurveTL -n "' .. tostring(nodeName) .. '_scaleX";\n') 
--								outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n') 
--								outFile:write('\tsetAttr ".tan" 2;\n') 
--								outFile:write('\tsetAttr ".wgt" no;\n') 
--								outFile:write('\tsetAttr -s ' .. tostring(total_keyframes) .. ' ".ktv[0:' .. tostring(total_keyframes - 1) .. ']"  ' .. sx_animated .. ';\n')
--								-- scaleY
--								outFile:write('createNode animCurveTL -n "' .. tostring(nodeName) .. '_scaleY";\n') 
--								outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n') 
--								outFile:write('\tsetAttr ".tan" 2;\n') 
--								outFile:write('\tsetAttr ".wgt" no;\n') 
--								outFile:write('\tsetAttr -s ' .. tostring(total_keyframes) .. ' ".ktv[0:' .. tostring(total_keyframes - 1) .. ']"  ' .. sy_animated .. ';\n')
--								-- scaleY

--								outFile:write('createNode animCurveTL -n "' .. tostring(nodeName) .. '_scale";\n') 
--								outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n') 
--								outFile:write('\tsetAttr ".tan" 2;\n') 
--								outFile:write('\tsetAttr ".wgt" no;\n') 
--								outFile:write('\tsetAttr -s ' .. tostring(total_keyframes) .. ' ".ktv[0:' .. tostring(total_keyframes - 1) .. ']"  ' .. sz_animated .. ';\n')

								-- Connect the animation curves
								outFile:write('connectAttr "' .. tostring(nodeName) .. '_translateX.o" "' .. tostring(nodeName) .. '.tx";\n')
								outFile:write('connectAttr "' .. tostring(nodeName) .. '_translateY.o" "' .. tostring(nodeName) .. '.ty";\n')
								outFile:write('connectAttr "' .. tostring(nodeName) .. '_translateZ.o" "' .. tostring(nodeName) .. '.tz";\n')

								outFile:write('connectAttr "' .. tostring(nodeName) .. '_rotateX.o" "' .. tostring(nodeName) .. '.rx";\n')
								outFile:write('connectAttr "' .. tostring(nodeName) .. '_rotateY.o" "' .. tostring(nodeName) .. '.ry";\n')
								outFile:write('connectAttr "' .. tostring(nodeName) .. '_rotateZ.o" "' .. tostring(nodeName) .. '.rz";\n')

								-- outFile:write('connectAttr "' .. tostring(nodeName) .. '_scaleX.o" "' .. tostring(nodeName) .. '.sx";\n')
								-- outFile:write('connectAttr "' .. tostring(nodeName) .. '_scaleY.o" "' .. tostring(nodeName) .. '.sy";\n')
								-- outFile:write('connectAttr "' .. tostring(nodeName) .. '_scaleZ.o" "' .. tostring(nodeName) .. '.sz";\n')
							end

							-- Write out the Maya ASCII footer
							-- Playback frame range
							outFile:write('createNode script -n "sceneConfigurationScriptNode";\n')
							outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n')
							outFile:write('\tsetAttr ".b" -type "string" "playbackOptions -min ' .. startFrame .. ' -max ' .. endFrame .. ' -ast ' .. startFrameGlobal .. ' -aet ' .. endFrameGlobal .. ' ";\n')
							outFile:write('\tsetAttr ".st" 6;\n')
							
							-- End timeline range
							outFile:write('select -ne :time1;\n')
							outFile:write('\tsetAttr ".o" ' .. endFrame .. ';\n')
							-- Current playhead timeline frame
							outFile:write('\tsetAttr ".unw" ' .. endFrame .. ';\n')
							outFile:write('// End of Maya ASCII\n')

							-- File writing complete
							outFile:write('\n')

							-- Close the file pointer on our Camera textfile
							outFile:close()

							print('[Export Camera] [File] ' .. tostring(pointcloudFile))

							-- Show the output folder using a desktop file browser
							openDirectory(outputDirectory)
						elseif fileExt == 'usda' then
							-- The system temporary directory path (Example: $TEMP/Kartaverse/)
							-- outputDirectory = comp:MapPath('Temp:\\Kartaverse\\')

							-- Open up the file pointer for the output textfile
							outFile, err = io.open(pointcloudFile,'w')
							if err then
								print('[Camera] [Error opening file for writing] ' .. tostring(pointcloudFile))
								disp:ExitLoop()
							end

							-- Write a PIXAR USD ASCII header entry
							outFile:write('#usda 1.0\n')
							outFile:write('(\n')
							outFile:write('\tdefaultPrim = "' .. tostring(nodeName) .. '"\n')
							if compFile and compFile ~= '' then
								-- The Fusion comp has a name so reference it in the usd ascii export
								outFile:write('\tdoc = """Generated from Composed Stage of root layer ' .. tostring(compFile) .. '"""\n')
							else
								-- Fallback - The Fusion comp is unsaved so just give this exported usd ascii file as the name
								outFile:write('\tdoc = """Generated from Composed Stage of root layer ' .. tostring(pointcloudFile) .. '"""\n')
							end

							outFile:write('\tmetersPerUnit = ' .. tostring(metersPerUnit) .. '\n')
							outFile:write('\tupAxis = "' .. tostring(upAxis) .. '"\n')
							outFile:write(')\n')
							outFile:write('\n')
							outFile:write('def Xform "' .. tostring(nodeName) .. '" (\n')
							outFile:write('\tkind = "assembly"\n')
							outFile:write(')\n')
							outFile:write('{\n')


							-- Should the PIXAR USD ASCII camera export be animated
							if usdAnimatedCamera == false then
								-- Static (non-animated) camera export
								-- Rotate XYZ
								outFile:write('\tfloat3 xformOp:rotateXYZ = (' .. rx .. ', ' .. ry .. ', ' .. rz .. ')\n')
								-- Translate XYZ
								outFile:write('\tdouble3 xformOp:translate = (' .. tx .. ', ' .. ty .. ', ' .. tz .. ')\n')
								outFile:write('\tuniform token[] xformOpOrder = ["xformOp:translate", "xformOp:rotateXYZ"]\n')
							else
								-- Animated camera export
								-- Rotate XYZ
								outFile:write('\tfloat3 xformOp:rotateXYZ.timeSamples = {\n')

								-- Per frame Rotate XYZ values start
								-- Step through the timeline at the comp's "StepBy" interval
								for frame = startFrame, endFrame, renderStep do
									rx = selectedNode:GetInput('Transform3DOp.Rotate.X', frame)
									ry = selectedNode:GetInput('Transform3DOp.Rotate.Y', frame)
									rz = selectedNode:GetInput('Transform3DOp.Rotate.Z', frame)
									print('\t[Frame] ' .. tostring(frame) .. ' [Rotate] [X] ' .. rx .. ' [Y] ' .. ry .. ' [Z] ' .. rz)

									-- Example: 1: (1.0, 2.0, 3.0),
									outFile:write('\t\t' .. frame .. ': (' .. rx .. ', ' .. ry .. ', ' .. rz .. '),\n')
								end

								-- Per frame Rotate XYZ values end
								outFile:write('\t}\n')

								-- Translate XYZ
								outFile:write('\tdouble3 xformOp:translate.timeSamples = {\n')

								-- Per frame Translate XYZ values start
								-- Step through the timeline at the comp's "StepBy" interval
								for frame = startFrame, endFrame, renderStep do
									tx = selectedNode:GetInput('Transform3DOp.Translate.X', frame)
									ty = selectedNode:GetInput('Transform3DOp.Translate.Y', frame)
									tz = selectedNode:GetInput('Transform3DOp.Translate.Z', frame)
									print('\t[Frame] ' .. tostring(frame) .. ' [Translate] [X] ' .. tx .. ' [Y] ' .. ty .. ' [Z] ' .. tz)

									-- Example: 1: (1.0, 2.0, 3.0),
									outFile:write('\t\t' .. frame .. ': (' .. tx .. ', ' .. ty .. ', ' .. tz .. '),\n')
								end
								-- Per frame Translate XYZ values end

								outFile:write('\t}\n')
								outFile:write('\tuniform token[] xformOpOrder = ["xformOp:translate", "xformOp:rotateXYZ"]\n')
							end

							-- Camera properties
							outFile:write('\n')
							outFile:write('\tdef Camera "' .. tostring(nodeName) .. 'Shape"\n')
							outFile:write('\t{\n')

							-- Camera visibility
							-- outFile:write('\t\ttoken visibility = "invisible"\n')

							-- Camera Near/Far clipping range
							outFile:write('\t\tfloat2 clippingRange = (' .. tostring(perspNearClip) .. ', ' .. tostring(perspFarClip) .. ')\n')

							-- Lens Focal length (mm)
							outFile:write('\t\tfloat focalLength = ' .. tostring(focalLength) ..'\n')

							-- Lens focus distance (in scene units)
							outFile:write('\t\tfloat focusDistance = ' .. tostring(focusDistance) .. '\n')

							-- f-Stop is a fixed (default) value that is not used inside of Fusion's Camera3D node
							outFile:write('\t\tfloat fStop = ' .. tostring(fStop) .. '\n')

							-- Camera Aperture (mm)
							-- Convert 1 inch into millimetres
							local inchesToMM = 25.4
							-- Horizontal Aperture (mm)
							outFile:write('\t\tfloat horizontalAperture = ' .. tonumber(apertureW * inchesToMM) .. '\n')
							-- Vertical Aperture (mm)
							outFile:write('\t\tfloat verticalAperture = ' .. tonumber(apertureH * inchesToMM) .. '\n')

							-- Write a Camera footer entry
							outFile:write('\t}\n')

							-- Write a PIXAR USD ASCII footer entry
							outFile:write('}\n')
							
							-- File writing complete
							outFile:write('\n')

							-- Close the file pointer on our Camera textfile
							outFile:close()

							print('[Export Camera] [File] ' .. tostring(pointcloudFile))

							-- Show the output folder using a desktop file browser
							openDirectory(outputDirectory)
						elseif fileExt == 'mov' then
							-- Maya MOVE ASCII (.mov) export
							-- The system temporary directory path (Example: $TEMP/Kartaverse/)
							-- outputDirectory = comp:MapPath('Temp:\\Kartaverse\\')

							-- Open up the file pointer for the output textfile
							outFile, err = io.open(pointcloudFile,'w')
							if err then
								print('[Camera] [Error opening file for writing] ' .. tostring(pointcloudFile))
								disp:ExitLoop()
							end

							-- Per frame Translate and Rotate XYZ values start
							-- Step through the timeline at the comp's "StepBy" interval
							for frame = startFrame, endFrame, renderStep do
								tx = selectedNode:GetInput('Transform3DOp.Translate.X', frame)
								ty = selectedNode:GetInput('Transform3DOp.Translate.Y', frame)
								tz = selectedNode:GetInput('Transform3DOp.Translate.Z', frame)

								rx = selectedNode:GetInput('Transform3DOp.Rotate.X', frame)
								ry = selectedNode:GetInput('Transform3DOp.Rotate.Y', frame)
								rz = selectedNode:GetInput('Transform3DOp.Rotate.Z', frame)

								print('\t[Frame] ' .. tostring(frame) .. ' [Translate] [X] ' .. tx .. ' [Y] ' .. ty .. ' [Z] ' .. tz)
								print('\t[Frame] ' .. tostring(frame) .. ' [Rotate] [X] ' .. rx .. ' [Y] ' .. ry .. ' [Z] ' .. rz)
								-- Example: 1.0 2.0 3.0 4.0 5.0 6.0
								outFile:write(tx .. ' ' .. ty .. ' ' .. tz .. ' ' .. rx .. ' ' .. ry .. ' ' .. rz .. '\n')
							end
							-- Per frame Translate and Rotate XYZ values end

							-- File writing complete
							outFile:write('\n')

							-- Close the file pointer on our Camera textfile
							outFile:close()

							print('[Export Camera] [File] ' .. tostring(pointcloudFile))

							-- Show the output folder using a desktop file browser
							openDirectory(outputDirectory)
						end
					elseif nodeType == 'SurfaceAlembicMesh' then
						-- Read the SurfaceAlembicMesh node settings
						-- Filename
						filename = comp:MapPath(selectedNode:GetInput('Filename'))

						-- Translate
						tx = selectedNode:GetInput('Transform3DOp.Translate.X')
						ty = selectedNode:GetInput('Transform3DOp.Translate.Y')
						tz = selectedNode:GetInput('Transform3DOp.Translate.Z')

						-- Rotate
						rx = selectedNode:GetInput('Transform3DOp.Rotate.X')
						ry = selectedNode:GetInput('Transform3DOp.Rotate.Y')
						rz = selectedNode:GetInput('Transform3DOp.Rotate.Z')

						-- Scale
						sx = selectedNode:GetInput('Transform3DOp.Scale.X')
						sy = selectedNode:GetInput('Transform3DOp.Scale.Y')
						sz = selectedNode:GetInput('Transform3DOp.Scale.Z')

						-- Results
						print('\t[Filename] ' .. tostring(filename))
						print('\t[Translate] [X] ' .. tx .. ' [Y] ' .. ty .. ' [Z] ' .. tz)
						print('\t[Rotate] [X] ' .. rx .. ' [Y] ' .. ry .. ' [Z] ' .. rz)
						print('\t[Scale] [X] ' .. sx .. ' [Y] ' .. sy .. ' [Z] ' .. sz)

						-- The system temporary directory path (Example: $TEMP/Kartaverse/)
						-- outputDirectory = comp:MapPath('Temp:\\Kartaverse\\')

						-- Open up the file pointer for the output textfile
						outFile, err = io.open(pointcloudFile,'w')
						if err then
							print('[Alembic Mesh] [Error opening file for writing] ' .. tostring(pointcloudFile))
							disp:ExitLoop()
						end

						-- Maya ASCII (.ma) export
						if fileExt == 'ma' then
							-- Write a Maya ASCII header entry
							outFile:write('//Maya ASCII scene\n')
							outFile:write('//Name: ' .. tostring(nodeName) .. '.' .. tostring(fileExt) .. '\n') 
							outFile:write('//Created by Kartaverse: ' ..  _VERSION .. '\n')
							outFile:write('//Created: ' .. tostring(os.date('%Y-%m-%d %I:%M:%S %p')) .. '\n')

							-- Alembic reference header entry
							-- Reference Alembic requires line
							outFile:write('requires "AbcImport" "1.0";;\n')
							outFile:write('file -rdi 1 -ns "' .. tostring(nodeName) .. '" -rfn "' .. tostring(nodeName) .. 'RN" -typ "Alembic" "' .. DupSlashes(filename) .. '";\n')
							outFile:write('file -r -ns "' .. tostring(nodeName) .. '" -dr 1 -rfn "' .. tostring(nodeName) .. 'RN" -typ "Alembic" "' .. DupSlashes(filename) .. '";\n')

							-- Standard Alembic requires line
							-- outFile:write('requires -nodeType "AlembicNode" "AbcImport" "1.0";\n')

							-- Rest of the Maya ASCII headers
							outFile:write('requires maya "2019";\n')
							outFile:write('currentUnit -l centimeter -a degree -t film;\n')
							outFile:write('fileInfo "application" "maya";\n')
							outFile:write('createNode transform -s -n "persp";\n')
							outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n')
							outFile:write('\tsetAttr ".v" no;\n')
							outFile:write('\tsetAttr ".t" -type "double3" 42.542190019936143 11.856220346068302 7.6545481521220538 ;\n')
							outFile:write('\tsetAttr ".r" -type "double3" -15.338352729601354 79.799999999999187 8.9803183372077805e-15 ;\n')
							outFile:write('createNode camera -s -n "perspShape" -p "persp";\n')
							outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n')
							outFile:write('\tsetAttr -k off ".v" no;\n')
							outFile:write('\tsetAttr ".fl" 34.999999999999986;\n')
							outFile:write('\tsetAttr ".coi" 44.82186966202994;\n')
							outFile:write('\tsetAttr ".imn" -type "string" "persp";\n')
							outFile:write('\tsetAttr ".den" -type "string" "persp_depth";\n')
							outFile:write('\tsetAttr ".man" -type "string" "persp_mask";\n')
							outFile:write('\tsetAttr ".hc" -type "string" "viewSet -p %camera";\n')

							-- Write out the SurfaceAlembicMesh node data
							-- outFile:write('createNode AlembicNode -n "' .. tostring(nodeName) .. '_AlembicNode";\n')
							-- outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n')
							-- outFile:write('\tsetAttr ".fn" -type "string" "' .. filename .. '";\n')
							-- outFile:write('\tsetAttr ".fns" -type "stringArray" 1 "' .. filename .. '"  ;\n')
							
							-- Write out the Maya Mesh Node + Transform Mode data
							-- outFile:write('createNode transform -n "' .. tostring(nodeName) .. '";\n')
							-- outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n')
							-- outFile:write('\tsetAttr ".t" -type "double3" ' .. tx .. ' ' .. ty .. ' ' .. tz .. ';\n')
							-- outFile:write('\tsetAttr ".r" -type "double3" ' .. rx .. ' ' .. ry .. ' ' .. rz .. ';\n')
							-- outFile:write('createNode mesh -n "' .. tostring(nodeName) .. 'Mesh_0" -p "' .. tostring(nodeName) .. '";\n')
							-- outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n')
							-- outFile:write('\tsetAttr -k off ".v";\n')
							-- outFile:write('\tsetAttr ".vir" yes;\n')
							-- outFile:write('\tsetAttr ".vif" yes;\n')
							-- outFile:write('\tsetAttr ".uvst[0].uvsn" -type "string" "map1";\n')
							-- outFile:write('\tsetAttr ".cuvs" -type "string" "map1";\n')
							-- outFile:write('\tsetAttr ".dcol" yes;\n')
							-- outFile:write('\tsetAttr ".dcc" -type "string" "Ambient+Diffuse";\n')
							-- outFile:write('\tsetAttr ".ccls" -type "string" "velocity";\n')
							-- outFile:write('\tsetAttr ".clst[0].clsn" -type "string" "velocity";\n')
							-- outFile:write('\tsetAttr ".covm[0]"  0 1 1;\n')
							-- outFile:write('\tsetAttr ".cdvm[0]"  0 1 1;\n')

							-- Connect the Alembic Node to the Mesh
							-- outFile:write('connectAttr "' .. tostring(nodeName) .. '_AlembicNode.opoly[0]" "' .. tostring(nodeName) .. 'Mesh_0.i";\n')

							-- Write out the SurfaceAlembicMesh node as Alembic Reference data
							outFile:write('createNode reference -n "' .. tostring(nodeName) .. 'RN";\n')
							outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n')
							outFile:write('\tsetAttr ".ed" -type "dataReferenceEdits" \n')
							outFile:write('\t\t"' .. tostring(nodeName) .. 'RN"\n')
							outFile:write('\t\t"' .. tostring(nodeName) .. 'RN" 0;\n')

							-- Write out the Maya ASCII footer
							-- Playback frame range
							outFile:write('createNode script -n "sceneConfigurationScriptNode";\n')
							outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n')
							outFile:write('\tsetAttr ".b" -type "string" "playbackOptions -min ' .. startFrame .. ' -max ' .. endFrame .. ' -ast ' .. startFrameGlobal .. ' -aet ' .. endFrameGlobal .. ' ";\n')
							outFile:write('\tsetAttr ".st" 6;\n')
							
							-- End timeline range
							outFile:write('select -ne :time1;\n')
							outFile:write('\tsetAttr ".o" ' .. endFrame .. ';\n')
							-- Current playhead timeline frame
							outFile:write('\tsetAttr ".unw" ' .. endFrame .. ';\n')
							outFile:write('// End of Maya ASCII\n')

							-- File writing complete
							outFile:write('\n')
						elseif fileExt == 'usda' then
							-- Write a PIXAR USD ASCII header entry
							outFile:write('#usda 1.0\n')
							outFile:write('(\n')
							outFile:write('\tdefaultPrim = "' .. tostring(nodeName) .. '"\n')
							if compFile and compFile ~= '' then
								-- The Fusion comp has a name so reference it in the usd ascii export
								outFile:write('\tdoc = """Generated from Composed Stage of root layer ' .. tostring(compFile) .. '"""\n')
							else
								-- Fallback - The Fusion comp is unsaved so just give this exported usd ascii file as the name
								outFile:write('\tdoc = """Generated from Composed Stage of root layer ' .. tostring(pointcloudFile) .. '"""\n')
							end

							outFile:write('\tmetersPerUnit = ' .. tostring(metersPerUnit) .. '\n')
							outFile:write('\tupAxis = "' .. tostring(upAxis) .. '"\n')
							outFile:write(')\n')
							outFile:write('\n')
							outFile:write('def Xform "' .. tostring(nodeName) .. '" (\n')
							outFile:write('\tkind = "assembly"\n')
							outFile:write(')\n')
							outFile:write('{\n')

							outFile:write('\tdef Xform "' .. tostring(nodeName) .. 'ReferenceAssembly" (\n')
							outFile:write('\t\tkind = "assembly"\n')
							outFile:write('\t\tprepend references = @' .. DupSlashes(filename) .. '@\n')
							outFile:write('\t)\n')

							-- AlembicMesh3D info
							-- Note: Fusion v9 appears to only support the Alembic HDF5 "legacy" (pre-Maya 2014 Extension 1) era .abc mesh format. Newer Ogawa formatted abc files fail to load in my tests. This means you need to have compiled PIXAR's open source "usdview" or your USD for Maya/Katana/Houdini/etc... plugins with HDF5 support enabled if you want to interact with Fusion compatible Alembic files.
							outFile:write('\t{\n')
							outFile:write('\t\tfloat3 xformOp:rotateXYZ = (' .. rx .. ', ' .. ry .. ', ' .. rz .. ')\n')
							outFile:write('\t\tdouble3 xformOp:translate = (' .. tx .. ', ' .. ty .. ', ' .. tz .. ')\n')
							outFile:write('\t\tuniform token[] xformOpOrder = ["xformOp:translate", "xformOp:rotateXYZ"]\n')
							outFile:write('\t}\n')

							-- Write a PIXAR USD ASCII footer entry
							outFile:write('}\n')
						elseif fileExt == 'mov' then
							-- Maya MOVE ASCII (.mov) export

							-- Per frame Translate and Rotate XYZ values start
							-- Step through the timeline at the comp's "StepBy" interval
							for frame = startFrame, endFrame, renderStep do
								tx = selectedNode:GetInput('Transform3DOp.Translate.X', frame)
								ty = selectedNode:GetInput('Transform3DOp.Translate.Y', frame)
								tz = selectedNode:GetInput('Transform3DOp.Translate.Z', frame)

								rx = selectedNode:GetInput('Transform3DOp.Rotate.X', frame)
								ry = selectedNode:GetInput('Transform3DOp.Rotate.Y', frame)
								rz = selectedNode:GetInput('Transform3DOp.Rotate.Z', frame)

								print('\t[Frame] ' .. tostring(frame) .. ' [Translate] [X] ' .. tx .. ' [Y] ' .. ty .. ' [Z] ' .. tz)
								print('\t[Frame] ' .. tostring(frame) .. ' [Rotate] [X] ' .. rx .. ' [Y] ' .. ry .. ' [Z] ' .. rz)
								-- Example: 1.0 2.0 3.0 4.0 5.0 6.0
								outFile:write(tx .. ' ' .. ty .. ' ' .. tz .. ' ' .. rx .. ' ' .. ry .. ' ' .. rz .. '\n')
							end
							-- Per frame Translate and Rotate XYZ values end

							-- File writing complete
							outFile:write('\n')
						end
						
						-- Close the file pointer on our Camera textfile
						outFile:close()
						print('[Export Alembic Mesh] [File] ' .. tostring(pointcloudFile))

						-- Show the output folder using a desktop file browser
						openDirectory(outputDirectory)
					elseif nodeType == 'PointCloud3D' then
						-- Grab the settings table for the PointCloud3D node
						local nodeTable = comp:CopySettings(selectedNode)
						-- print('[PointCloud3D Settings]')
						-- dump(nodeTable)

						-- The system temporary directory path (Example: $TEMP/Kartaverse/)
						-- outputDirectory = comp:MapPath('Temp:\\Kartaverse\\')

						-- Open up the file pointer for the output textfile
						outFile, err = io.open(pointcloudFile,'w')
						if err then
							print('[Point Cloud] [Error opening file for writing] ' .. tostring(pointcloudFile))
							disp:ExitLoop()
						end


						if fileExt == 'mov' then
							-- Maya MOVE ASCII (.mov) export

							-- Per frame Translate and Rotate XYZ values start
							-- Step through the timeline at the comp's "StepBy" interval
							for frame = startFrame, endFrame, renderStep do
								tx = selectedNode:GetInput('Transform3DOp.Translate.X', frame)
								ty = selectedNode:GetInput('Transform3DOp.Translate.Y', frame)
								tz = selectedNode:GetInput('Transform3DOp.Translate.Z', frame)

								rx = selectedNode:GetInput('Transform3DOp.Rotate.X', frame)
								ry = selectedNode:GetInput('Transform3DOp.Rotate.Y', frame)
								rz = selectedNode:GetInput('Transform3DOp.Rotate.Z', frame)

								print('\t[Frame] ' .. tostring(frame) .. ' [Translate] [X] ' .. tx .. ' [Y] ' .. ty .. ' [Z] ' .. tz)
								print('\t[Frame] ' .. tostring(frame) .. ' [Rotate] [X] ' .. rx .. ' [Y] ' .. ry .. ' [Z] ' .. rz)
								-- Example: 1.0 2.0 3.0 4.0 5.0 6.0
								outFile:write(tx .. ' ' .. ty .. ' ' .. tz .. ' ' .. rx .. ' ' .. ry .. ' ' .. rz .. '\n')
							end
							-- Per frame Translate and Rotate XYZ values end

							-- File writing complete
							outFile:write('\n')

						-- Check for a non nil settings lua table
						elseif nodeTable and nodeTable['Tools'] and nodeTable['Tools'][nodeName] and nodeTable['Tools'][nodeName]['Positions'] then
							-- Grab the positions Lua table elements
							local positionsTable = nodeTable['Tools'][nodeName]['Positions'] or {}
							local positionsElements = tonumber(table.getn(positionsTable))


							-- Handle array off by 1
							vertexCount = 0
							if positionsTable[0] then
								vertexCount = tonumber(positionsElements + 1)
							end

							if fileExt == 'ma' then
								-- Write a Maya ASCII header entry
								outFile:write('//Maya ASCII scene\n')
								outFile:write('//Name: ' .. tostring(nodeName) .. '.' .. tostring(fileExt) .. '\n') 
								outFile:write('//Created by Kartaverse: ' ..  _VERSION .. '\n')
								outFile:write('//Created: ' .. tostring(os.date('%Y-%m-%d %I:%M:%S %p')) .. '\n')
								outFile:write('//Locator Count: ' ..tostring(vertexCount) .. '\n')
								outFile:write('requires maya "2019";\n')
								outFile:write('currentUnit -l centimeter -a degree -t film;\n')
								outFile:write('fileInfo "application" "maya";\n')
								outFile:write('createNode transform -s -n "persp";\n')
								outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n')
								outFile:write('\tsetAttr ".v" no;\n')
								outFile:write('\tsetAttr ".t" -type "double3" 42.542190019936143 11.856220346068302 7.6545481521220538 ;\n')
								outFile:write('\tsetAttr ".r" -type "double3" -15.338352729601354 79.799999999999187 8.9803183372077805e-15 ;\n')
								outFile:write('createNode camera -s -n "perspShape" -p "persp";\n')
								outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n')
								outFile:write('\tsetAttr -k off ".v" no;\n')
								outFile:write('\tsetAttr ".fl" 34.999999999999986;\n')
								outFile:write('\tsetAttr ".coi" 44.82186966202994;\n')
								outFile:write('\tsetAttr ".imn" -type "string" "persp";\n')
								outFile:write('\tsetAttr ".den" -type "string" "persp_depth";\n')
								outFile:write('\tsetAttr ".man" -type "string" "persp_mask";\n')
								outFile:write('\tsetAttr ".hc" -type "string" "viewSet -p %camera";\n')
								outFile:write('createNode transform -n "PointCloudGroup";\n')
								outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n')
							elseif fileExt == 'usda' then
								-- Write a PIXAR USD ASCII header entry
								outFile:write('#usda 1.0\n')
								outFile:write('(\n')
								outFile:write('\tdefaultPrim = "persp"\n')
								outFile:write('\tdoc = """Generated from Composed Stage of root layer ' .. tostring(pointcloudFile) .. '"""\n')
								outFile:write('\tmetersPerUnit = ' .. tostring(metersPerUnit) .. '\n')
								outFile:write('\tupAxis = "' .. tostring(upAxis) .. '"\n')
								outFile:write(')\n')
								outFile:write('\n')
								outFile:write('def Xform "PointCloudGroup" (\n')
								outFile:write('\tkind = "assembly"\n')
								outFile:write(')\n')
								outFile:write('{\n')
							elseif fileExt == 'ply' then
								-- Write a ply ASCII header entry
								outFile:write('ply\n')
								outFile:write('format ascii 1.0\n')
								outFile:write('comment Created by Kartaverse ' ..  _VERSION .. '\n')
								outFile:write('comment Created ' .. tostring(os.date('%Y-%m-%d %I:%M:%S %p')) .. '\n')
								outFile:write('obj_info Generated by Kartaverse!\n')
								outFile:write('element vertex ' .. tostring(vertexCount) .. '\n')
								outFile:write('property float x\n')
								outFile:write('property float y\n')
								outFile:write('property float z\n')
								outFile:write('end_header\n')
							end

							-- Scan through the positions table
							for i = 0, positionsElements do
								-- Check if there are 5+ elements are in the positions table element. We only need 4 of those elements at this time.
								local tableElements = table.getn(positionsTable[i] or {})
								if tableElements >= 4 then
									local x, y, z, name = positionsTable[i][1], positionsTable[i][2], positionsTable[i][3], positionsTable[i][4]

									-- Display the data for one point cloud sample
									print('[' .. tostring(i + 1) .. '] [' .. tostring(name) .. '] [XYZ] ' .. tostring(x) .. ' ' .. tostring(y) .. ' ' .. tostring(z))

									-- Write the point cloud data
									if fileExt == 'ma' then
										-- ma (Maya ASCII)
										outFile:write('createNode transform -n "locator' .. tostring(i + 1) .. '" -p "PointCloudGroup";\n')
										outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n')
										outFile:write('\tsetAttr ".t" -type "double3" ' .. tostring(x) .. ' ' .. tostring(y) .. ' ' .. tostring(z) .. ';\n')
										outFile:write('\tsetAttr ".s" -type "double3" ' .. mayaLocatorSize .. " " .. mayaLocatorSize .. " " .. mayaLocatorSize .. ';\n')
										outFile:write('createNode locator -n "locatorShape' .. tostring(i + 1) .. '" -p "locator' .. tostring(i + 1) .. '";\n')
										outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n')
										outFile:write('\tsetAttr -k off ".v";\n')
									elseif fileExt == 'usda' then
										-- usdz (USD ASCII)
										outFile:write('\n')
										outFile:write('\tdef Xform "locator' .. tostring(i + 1) .. '"\n')
										outFile:write('\t{\n')
										outFile:write('\t\tdouble3 xformOp:translate = (' .. tostring(x) .. ', ' .. tostring(y) .. ', ' .. tostring(z) .. ')\n')
										outFile:write('\t\tuniform token[] xformOpOrder = ["xformOp:translate"]\n')
										outFile:write('\t}\n')
									elseif fileExt == 'ply' then
										-- ply - Add a trailing space before the newline character
										outFile:write(tostring(x) .. ' ' .. tostring(y) .. ' ' .. tostring(z) .. ' ' .. '\n')
									else
										-- xyz
										outFile:write(tostring(x) .. ' ' .. tostring(y) .. ' ' .. tostring(z) .. '\n')
									end
								else
									print('[Error][PointCloud3D Positions] Not enough table elements. Only ' .. tostring(tableElements) .. ' were found. 5 are expected.')
									disp:ExitLoop()
								end
							end
							
							if fileExt == 'ma' then
								-- Write out the Maya ASCII footer
								-- Playback frame range
								outFile:write('createNode script -n "sceneConfigurationScriptNode";\n')
								outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n')
								outFile:write('\tsetAttr ".b" -type "string" "playbackOptions -min ' .. startFrame .. ' -max ' .. endFrame .. ' -ast ' .. startFrameGlobal .. ' -aet ' .. endFrameGlobal .. ' ";\n')
								outFile:write('\tsetAttr ".st" 6;\n')
							
								-- End timeline range
								outFile:write('select -ne :time1;\n')
								outFile:write('\tsetAttr ".o" ' .. endFrame .. ';\n')
								-- Current playhead timeline frame
								outFile:write('\tsetAttr ".unw" ' .. endFrame .. ';\n')
								outFile:write('// End of Maya ASCII\n')
							elseif fileExt == 'usda' then
								-- Write out the USD ASCII footer
								outFile:write('}\n')
							end

							-- File writing complete
							outFile:write('\n')

							-- Close the file pointer on our point cloud textfile
							outFile:close()

							-- List how many PointCloud3D vertices were found in the OBJ mesh
							print('[PointCloud3D Positions] ' .. tostring(vertexCount))
							print('[OpenUSD Scene Exporter] [File] ' .. tostring(pointcloudFile))

							-- Show the output folder using a desktop file browser
							openDirectory(outputDirectory)
						else
							print('[Error][PointCloud3D Positions] No points found on ' .. tostring(nodeName) .. ' node.')
							disp:ExitLoop()
						end
					elseif nodeType == 'SurfaceFBXMesh' then
						meshFile = selectedNode:GetInput('ImportFile')
						
						-- Display the name of the source FBX/OBJ mesh
						print('[FBXMesh3D Source File] ' .. tostring(meshFile))

						-- The system temporary directory path (Example: $TEMP/Kartaverse/)
						-- outputDirectory = comp:MapPath('Temp:\\Kartaverse\\')

						-- Use the Export Directory from the UI Manager GUI
						outputDirectory = pointcloudFolder
						os.execute('mkdir "' .. outputDirectory ..'"')

						pointcloudFile = ''

						-- Save a copy of the point cloud to the $TEMP/Kartaverse/ folder
						pointcloudFile = outputDirectory .. nodeName .. '.' .. fileExt
						print('[PointCloud3D Format] "' .. tostring(exportFormat) .. '"')

						-- Open up the file pointer for the output textfile
						outFile, err = io.open(pointcloudFile,'w')
						if err then
							print('[Point Cloud] [Error opening file for writing] ' .. tostring(pointcloudFile))
							disp:ExitLoop()
						end

						if fileExt == 'mov' then
							-- Maya MOVE ASCII (.mov) export

							-- Per frame Translate and Rotate XYZ values start
							-- Step through the timeline at the comp's "StepBy" interval
							for frame = startFrame, endFrame, renderStep do
								tx = selectedNode:GetInput('Transform3DOp.Translate.X', frame)
								ty = selectedNode:GetInput('Transform3DOp.Translate.Y', frame)
								tz = selectedNode:GetInput('Transform3DOp.Translate.Z', frame)

								rx = selectedNode:GetInput('Transform3DOp.Rotate.X', frame)
								ry = selectedNode:GetInput('Transform3DOp.Rotate.Y', frame)
								rz = selectedNode:GetInput('Transform3DOp.Rotate.Z', frame)

								print('\t[Frame] ' .. tostring(frame) .. ' [Translate] [X] ' .. tx .. ' [Y] ' .. ty .. ' [Z] ' .. tz)
								print('\t[Frame] ' .. tostring(frame) .. ' [Rotate] [X] ' .. rx .. ' [Y] ' .. ry .. ' [Z] ' .. rz)
								-- Example: 1.0 2.0 3.0 4.0 5.0 6.0
								outFile:write(tx .. ' ' .. ty .. ' ' .. tz .. ' ' .. rx .. ' ' .. ry .. ' ' .. rz .. '\n')
							end
							-- Per frame Translate and Rotate XYZ values end

							-- File writing complete
							outFile:write('\n')
						elseif meshFile and string.match(string.lower(meshFile), '^.+(%..+)$') == '.obj' then
							-- Display the name of the source OBJ mesh

							-- Count the number of vertices in the file for the PLY header
							local vertexCount = 0
							for oneLine in io.lines(comp:MapPath(meshFile)) do
								-- One line of data
								-- print('[' .. vertexCount .. '] ' .. oneLine)

								-- Check if this line is an OBJ vertex
								local searchString = '^v%s.*'
								if oneLine:match(searchString) then
									-- Track how many vertices were found
									vertexCount = vertexCount + 1
								end
							end

							if fileExt == 'ma' then
								-- Write a Maya ASCII header entry
								outFile:write('//Maya ASCII scene\n')
								outFile:write('//Name: ' .. tostring(nodeName) .. '.' .. tostring(fileExt) .. '\n') 
								outFile:write('//Created by Kartaverse: ' ..  _VERSION .. '\n')
								outFile:write('//Created: ' .. tostring(os.date('%Y-%m-%d %I:%M:%S %p')) .. '\n')
								outFile:write('//Locator Count: ' ..tostring(vertexCount) .. '\n')
								outFile:write('requires maya "2019";\n')
								outFile:write('currentUnit -l centimeter -a degree -t film;\n')
								outFile:write('fileInfo "application" "maya";\n')
								outFile:write('createNode transform -s -n "persp";\n')
								outFile:write('\trename -uid "BDD1D327-CA4A-FAF4-4EC1-508AA473BFD6";\n')
								outFile:write('\tsetAttr ".v" no;\n')
								outFile:write('\tsetAttr ".t" -type "double3" 42.542190019936143 11.856220346068302 7.6545481521220538 ;\n')
								outFile:write('\tsetAttr ".r" -type "double3" -15.338352729601354 79.799999999999187 8.9803183372077805e-15 ;\n')
								outFile:write('createNode camera -s -n "perspShape" -p "persp";\n')
								outFile:write('\trename -uid "B4797D18-2047-C2A9-CAF1-8998F20276B3";\n')
								outFile:write('\tsetAttr -k off ".v" no;\n')
								outFile:write('\tsetAttr ".fl" 34.999999999999986;\n')
								outFile:write('\tsetAttr ".coi" 44.82186966202994;\n')
								outFile:write('\tsetAttr ".imn" -type "string" "persp";\n')
								outFile:write('\tsetAttr ".den" -type "string" "persp_depth";\n')
								outFile:write('\tsetAttr ".man" -type "string" "persp_mask";\n')
								outFile:write('\tsetAttr ".hc" -type "string" "viewSet -p %camera";\n')
								outFile:write('createNode transform -n "PointCloudGroup";\n')
								outFile:write('\trename -uid "6A38A338-4C48-6A5F-2EFE-D79EFCBFBA09";\n')
							elseif fileExt == 'usda' then
								-- Write a PIXAR USD ASCII header entry
								outFile:write('#usda 1.0\n')
								outFile:write('(\n')
								outFile:write('\tdefaultPrim = "locator' .. tostring(0) .. '"\n')
								outFile:write('\tdoc = """Generated from Composed Stage of root layer ' .. tostring(pointcloudFile) .. '"""\n')
								outFile:write('\tmetersPerUnit = ' .. tostring(metersPerUnit) .. '\n')
								outFile:write('\tupAxis = "' .. tostring(upAxis) .. '"\n')
								outFile:write(')\n')
								outFile:write('\n')
								outFile:write('def Xform "PointCloudGroup" (\n')
								outFile:write('\tkind = "assembly"\n')
								outFile:write(')\n')
								outFile:write('{\n')
							elseif fileExt == 'ply' then
								-- Write a ply ASCII header entry
								outFile:write('ply\n')
								outFile:write('format ascii 1.0\n')
								outFile:write('comment Created by Kartaverse ' ..  _VERSION .. '\n')
								outFile:write('comment Created ' .. tostring(os.date('%Y-%m-%d %I:%M:%S %p')) .. '\n')
								outFile:write('obj_info Generated by Kartaverse!\n')
								outFile:write('element vertex ' .. tostring(vertexCount) .. '\n')
								outFile:write('property float x\n')
								outFile:write('property float y\n')
								outFile:write('property float z\n')
								outFile:write('end_header\n')
							end

							local lineCounter = 0
							for oneLine in io.lines(comp:MapPath(meshFile)) do
								-- One line of data
								-- print('[' .. lineCounter .. '] ' .. oneLine)

								-- Check if this line is an OBJ vertex
								local searchString = '^v%s.*'
								if oneLine:match(searchString) then
									-- Extract the vertex XYZ positions, using %s as a white space character
									-- Example: v 0.5 0.5 -0.5
									local x, y, z = string.match(oneLine, '^v%s(%g+)%s(%g+)%s(%g+)')
									-- Write the point cloud data
									
									i = lineCounter
									if fileExt == 'ma' then
										-- ma (Maya ASCII)
										outFile:write('createNode transform -n "locator' .. tostring(i + 1) .. '" -p "PointCloudGroup";\n')
										outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n')
										outFile:write('\tsetAttr ".t" -type "double3" ' .. tostring(x) .. ' ' .. tostring(y) .. ' ' .. tostring(z) .. ';\n')
										outFile:write('\tsetAttr ".s" -type "double3" ' .. mayaLocatorSize .. " " .. mayaLocatorSize .. " " .. mayaLocatorSize .. ';\n')
										outFile:write('createNode locator -n "locatorShape' .. tostring(i + 1) .. '" -p "locator' .. tostring(i + 1) .. '";\n')
										outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n')
										outFile:write('\tsetAttr -k off ".v";\n')
									elseif fileExt == 'usda' then
										-- usdz (USD ASCII)
										outFile:write('\n')
										outFile:write('\tdef Xform "locator' .. tostring(i + 1) .. '"\n')
										outFile:write('\t{\n')
										outFile:write('\t\tdouble3 xformOp:translate = (' .. tostring(x) .. ', ' .. tostring(y) .. ', ' .. tostring(z) .. ')\n')
										outFile:write('\t\tuniform token[] xformOpOrder = ["xformOp:translate"]\n')
										outFile:write('\t}\n')
									elseif fileExt == 'ply' then
										-- ply - Add a trailing space before the newline character
										outFile:write(tostring(x) .. ' ' .. tostring(y) .. ' ' .. tostring(z) .. ' ' .. '\n')
									else
										-- xyz
										outFile:write(tostring(x) .. ' ' .. tostring(y) .. ' ' .. tostring(z) .. '\n')
									end

									-- Track how many vertices were found
									lineCounter = lineCounter + 1
								end
							end

							if fileExt == 'ma' then
								-- Write out the Maya ASCII footer
								-- Playback frame range
								outFile:write('createNode script -n "sceneConfigurationScriptNode";\n')
								outFile:write('\trename -uid "' .. tostring(bmd.createuuid()) .. '";\n')
								outFile:write('\tsetAttr ".b" -type "string" "playbackOptions -min ' .. startFrame .. ' -max ' .. endFrame .. ' -ast ' .. startFrameGlobal .. ' -aet ' .. endFrameGlobal .. ' ";\n')
								outFile:write('\tsetAttr ".st" 6;\n')
							
								-- End timeline range
								outFile:write('select -ne :time1;\n')
								outFile:write('\tsetAttr ".o" ' .. endFrame .. ';\n')
								-- Current playhead timeline frame
								outFile:write('\tsetAttr ".unw" ' .. endFrame .. ';\n')
								outFile:write('// End of Maya ASCII\n')
							elseif fileExt == 'usda' then
								-- Write out the USD ASCII footer
								outFile:write('}\n')
							end

							-- File writing complete
							outFile:write('\n')

							-- List how many FBXMesh3D vertices were found in the OBJ mesh
							print('[FBXMesh3D Positions] ' .. tostring(vertexCount))
						else
							print('[Error][OpenUSD Scene Exporter] Please select an FBXMesh3D node that has an OBJ model loaded.')
							disp:ExitLoop()
						end

						-- Close the file pointer on our point cloud textfile
						outFile:close()

						print('[Export PointCloud3D] [File] ' .. tostring(pointcloudFile))

						-- Show the output folder using a desktop file browser
						openDirectory(outputDirectory)
					else
						print('[Error][OpenUSD Scene Exporter] No PointCloud3D or FBXMesh3D node was selected. Please select either a PointCloud3D node or an FBXMesh3D node in the flow view and run the script again.')
						disp:ExitLoop()
					end
				else
					print('[Error][OpenUSD Scene Exporter] No PointCloud3D or FBXMesh3D node was selected. Please select either a PointCloud3D node or an FBXMesh3D node in the flow view and run the script again.')
					disp:ExitLoop()
				end

				disp:ExitLoop()
			end
		end
	end

	-- The Select Folder Button was clicked
	function epcwin.On.SelectFolderButton.Clicked(ev)
		selectedPath = fusion:RequestDir(exportDirectory)
		if selectedPath ~= nil then
			print('[Select Folder] "' .. tostring(selectedPath) .. '"')
			epcitm.ExportDirectoryText.Text = tostring(selectedPath)
		else
			print('[Select Folder] Cancelled Dialog')
		end
	end

	-- The Cancel Button was clicked
	function epcwin.On.CancelButton.Clicked(ev)
		epcwin:Hide()
		print('[OpenUSD Scene Exporter] Cancelled')
		disp:ExitLoop()
	end

	-- The app:AddConfig() command that will capture the "Control + W" or "Control + F4" hotkeys so they will close the window instead of closing the foreground composite.
	app:AddConfig('OpenUSDSceneExporter', {
		Target {
			ID = 'OpenUSDSceneExporter',
		},

		Hotkeys {
			Target = 'OpenUSDSceneExporter',
			Defaults = true,

			CONTROL_W = 'Execute{ cmd = [[app.UIManager:QueueEvent(obj, "Close", {})]] }',
			CONTROL_F4 = 'Execute{ cmd = [[app.UIManager:QueueEvent(obj, "Close", {})]] }',
		},
	})

	-- Point Cloud Export format list:
	FormatTable = {
		{text = 'XYZ ASCII (.xyz)'},
		{text = 'PLY ASCII (.ply)'},
		{text = 'Maya ASCII (.ma)'},
		{text = 'Maya MOVE ASCII (.mov)'},
		{text = 'PIXAR USDA ASCII (.usda)'},
	}

	-- Add the Format entries to the ComboControl menu
	for i = 1, table.getn(FormatTable) do
		if FormatTable[i].text ~= nil then
			epcitm.FormatCombo:AddItem(FormatTable[i].text)
		end
	end

	-- The default value for the Point Cloud Format ComboBox
	epcitm.FormatCombo.CurrentIndex = GetPreferenceData('CompX.OpenUSDSceneExporter.PointCloudFormat', 0, false)

	-- We want to be notified whenever the 'Comp_Activate_Tool' action has been executed
	local notify = ui:AddNotify('Comp_Activate_Tool', comp)

	-- The Fusion "Comp_Activate_Tool" command was used
	function disp.On.Comp_Activate_Tool(ev)
		-- Verify a PointCloud3D node was selected
		if ev and ev.Args and ev.Args.tool then
			if ev.Args.tool:GetAttrs('TOOLS_RegID') == 'PointCloud3D' then
				-- PointCloud3D node 
				-- Update the selected node
				selectedNode = ev.Args.tool:GetAttrs('TOOLS_Name')

				print('[Selected ' .. tostring(ev.Args.tool:GetAttrs('TOOLS_RegID')) .. ' Node] ' .. tostring(selectedNode or 'None'))
				epcitm.NodeNameText.Text = tostring(selectedNode or '')
			elseif ev.Args.tool:GetAttrs('TOOLS_RegID') == 'SurfaceFBXMesh' then
				-- FBXMesh3D node with an OBJ model present
				meshFile = ev.Args.tool:GetInput('ImportFile')
				-- Make sure its not a nil
				if meshFile and string.match(string.lower(meshFile), '^.+(%..+)$') == '.obj' then
					-- Update the selected node
					selectedNode = ev.Args.tool:GetAttrs('TOOLS_Name')

					print('[Selected ' .. tostring(ev.Args.tool:GetAttrs('TOOLS_RegID')) .. ' Node] ' .. tostring(selectedNode or 'None'))
					epcitm.NodeNameText.Text = tostring(selectedNode or '')
				else
					print('[Error] [Selected ' .. tostring(ev.Args.tool:GetAttrs('TOOLS_RegID')) .. ' Node] Does not have an OBJ model loaded in ' .. tostring(selectedNode or 'None'))
				end
			end
		end
	end

	epcwin:Show()
	disp:RunLoop()
	epcwin:Hide()

	-- Cleanup after the window was closed
	app:RemoveConfig('OpenUSDSceneExporter')
	collectgarbage()

	return epcwin,epcwin:GetItems()
end

------------------------------------------------------------------------
-- Where the magic happens
function Main()
	-- Check if Fusion is running
	if not fusion then
		print('[Error] This script needs to be run from inside of Fusion.')
		return
	end

	-- Check if a composite is open in Fusion Standalone or the Resolve Fusion page
	if not comp then
		print('[Error] A Fusion composite needs to be open.')
		return
	end

	print('[Kartaverse][CompX][OpenUSD Scene Exporter] ' .. tostring(_VERSION))
	print('[Created By] Andrew Hazelden <andrew@andrewhazelden.com>')
	
	-- Show the UI Manager GUI
	OpenUSDSceneExporterWin()
end


-- Run the main function
Main()
print('[Done]')
