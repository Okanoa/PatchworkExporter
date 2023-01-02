local json = dofile("./json.lua")

local s = app.activeSprite

if not s then app.alert("No Sprite") return end

local dlg = Dialog { title = "Export Patchwork JSON"}

dlg:file{ id="spriteData",
          label="Save Sprite Sheet",
          title="Output File",
          save=false,
          open=false, 
          filename=app.fs.fileTitle(s.filename)..".png",
          filetypes={"png", "json"},
          entry=true}

dlg:button {id = "export",
            text = "Export",
onclick = function()

  local JsonPath = app.fs.filePathAndTitle(dlg.data.spriteData)..".json"
  local SpritePath = app.fs.filePathAndTitle(dlg.data.spriteData)..".png"

  local success = app.command.ExportSpriteSheet {
    ui=false,
    askOverwrite=true,
    type=SpriteSheetType.PACKED,
    columns=0,
    rows=0,
    width=0,
    height=0,
    bestFit=true,
    textureFilename=SpritePath,
    dataFilename=JsonPath,
    dataFormat=SpriteSheetDataFormat.JSON_ARRAY,
    filenameFormat="{frame}",
    borderPadding=0,
    shapePadding=0,
    innerPadding=0,
    trimSprite=false,
    trim=true,
    trimByGrid=false,
    extrude=false,
    ignoreEmpty=false,
    mergeDuplicates=true,
    openGenerated=false,
    layer="",
    tag="",
    splitLayers=false,
    splitTags=false,
    splitGrid=false,
    listLayers=false,
    listTags=true,
    listSlices=true,
    fromTilesets=false,
  }

  local file = io.open( JsonPath, "r" )
  local data = json.decode(file:read( "*all" ))
  file:close()


  local dataOut = {
    groups = {},
    spritesheet = app.fs.fileTitle(dlg.data.spriteData)..".png",
    frames = {}
  }

  local offset = {x = 0, y = 0} -- potential per sprite/group offset would be nice tbh...
  
  local slice = data["meta"]["slices"]
  if #slice > 0 then
    local sliceBounds = slice[1]["keys"][1]["bounds"]
    offset.x = sliceBounds.x
    offset.y = sliceBounds.y
  end

  -- frame atlas
  for i, framedat in ipairs(data["frames"]) do
    dataOut.frames[i] = {
      ox = offset.x-framedat.spriteSourceSize.x,
      oy = offset.y-framedat.spriteSourceSize.y,
      x = framedat.frame.x,
      y = framedat.frame.y,
      w = framedat.frame.w,
      h = framedat.frame.h
    }
  end

  local frameConv = 1000 / 60 -- 100/frameconv will result in how many frames something should last :)

  -- groups and sequences

  for _, tagDat in ipairs(data["meta"]["frameTags"]) do
    local rotation_group = {
      sequence = {},
      loop = true -- cannot be set to otherwise here!
    }
    
    -- make our rotation group if need be.
    if dataOut.groups[ tagDat["name"] ] then
      local group = dataOut.groups[ tagDat["name"] ]
      group[#group+1] = rotation_group
    else
      dataOut.groups[ tagDat["name"] ] = {
        rotation_group
      }
    end

    for i = tagDat["from"]+1, tagDat["to"]+1, 1 do
      local frameData = data["frames"][i]
      rotation_group.sequence[#rotation_group.sequence+1] = {
        frame = i,
        time = frameData["duration"]/frameConv
      }
    end


  end

  local file = io.open( JsonPath, "w" )
  file:write( json.encode(dataOut) )
  file:close()

  dlg:close()
end
}

dlg:button {id = "cancel",
            text = "Cancel",
onclick = function()
dlg:close()
end
}

dlg:show { wait = true }
