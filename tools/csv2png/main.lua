-- CLI: converts a CSV grid of 0/1 cells into an RGBA PNG image, using
-- love.image for the actual PNG encoding.
-- 1 -> the given color (opaque), 0 -> fully transparent.
-- Usage: love tools/csv2png <input.csv> <output.png> <RRGGBB> [scale]
--   scale: optional integer, each CSV cell becomes a scale x scale pixel block (default 1)

local function parse_color(hex_color)
    local hex = hex_color:gsub("^#", "")
    if not hex:match("^%x%x%x%x%x%x$") then
        error(string.format("color %q must be 6 hex digits, e.g. FF8800 or #FF8800", hex_color))
    end
    return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

local function parse_csv(path)
    local file = assert(io.open(path, "r"), "cannot open " .. path)
    local rows = {}
    for line in file:lines() do
        line = line:gsub("\r$", "")
        if #line > 0 then
            local row = {}
            for cell in line:gmatch("[^,]+") do
                cell = cell:match("^%s*(.-)%s*$")
                if cell ~= "0" and cell ~= "1" then
                    error(string.format("invalid cell %q in %s (only 0 or 1 allowed)", cell, path))
                end
                row[#row + 1] = cell
            end
            rows[#rows + 1] = row
        end
    end
    file:close()

    if #rows == 0 then
        error(path .. " has no data rows")
    end
    local width = #rows[1]
    for i, row in ipairs(rows) do
        if #row ~= width then
            error(string.format("row %d has %d columns, expected %d (all rows must match)", i, #row, width))
        end
    end
    return rows, width, #rows
end

local function run(argv)
    local input_path, output_path, hex_color = argv[1], argv[2], argv[3]
    if not input_path or not output_path or not hex_color then
        print("Usage: love tools/csv2png <input.csv> <output.png> <RRGGBB> [scale]")
        return 1
    end
    if argv[4] and not tonumber(argv[4]) then
        error(string.format("scale %q must be a number", argv[4]))
    end
    local scale = argv[4] and tonumber(argv[4]) or 1
    if scale < 1 or scale ~= math.floor(scale) then
        error("scale must be a positive integer")
    end

    local r, g, b = parse_color(hex_color)
    local rows, width, height = parse_csv(input_path)
    local out_width, out_height = width * scale, height * scale

    -- newImageData starts every pixel at (0,0,0,0), which is exactly the
    -- transparent "0" cell we want, so only "1" cells need setPixel calls.
    local imageData = love.image.newImageData(out_width, out_height)
    for row_index, row in ipairs(rows) do
        for col_index, cell in ipairs(row) do
            if cell == "1" then
                local base_x, base_y = (col_index - 1) * scale, (row_index - 1) * scale
                for dy = 0, scale - 1 do
                    for dx = 0, scale - 1 do
                        imageData:setPixel(base_x + dx, base_y + dy, r, g, b, 1)
                    end
                end
            end
        end
    end

    local fileData = imageData:encode("png")
    local out_file = assert(io.open(output_path, "wb"))
    out_file:write(fileData:getString())
    out_file:close()

    print(string.format("wrote %dx%d PNG (%d bytes) to %s", out_width, out_height, fileData:getSize(), output_path))
    return 0
end

function love.load(argv)
    local ok, result = pcall(run, argv)
    if not ok then
        io.stderr:write("error: " .. tostring(result) .. "\n")
        love.event.quit(1)
        return
    end
    love.event.quit(result)
end
