local tbl_node = 'pipe_table'

local tbl_cell = 'pipe_table_cell'
local tbl_delimiter_cell = 'pipe_table_delimiter_cell'

local tbl_header = 'pipe_table_header'
local tbl_delimiter_row = 'pipe_table_delimiter_row'
local tbl_row = 'pipe_table_row'

local tbl_align_left = 'pipe_table_align_left'
local tbl_align_right = 'pipe_table_align_right'

local tbl_node_len = #tbl_node

local conf = require('table-nvim.config')

local M = {}

---Returns `true` if the node is the root of a markdown table and `false` otherwise.
---@param node TSNode The node to check.
function M.is_tbl_root(node)
  return node:type() == tbl_node
end

---Returns `true` if the node belongs to a markdown table and `false` otherwise.
---@param node TSNode The node to check.
function M.is_tbl_node(node)
  return string.sub(node:type(), 1, tbl_node_len) == tbl_node
end

---@param node TSNode? A node within a markdown table
---@return TSNode? tbl_root Root node of a markdown table, if the `node` does not belong to a markdown table, then `nil` is returned
function M.get_tbl_root(node)
  if node == nil then return nil end
  if string.sub(node:type(), 1, tbl_node_len) ~= tbl_node then return nil end

  if M.is_tbl_root(node) then return node end

  while true do
    node = node:parent()
    if node == nil then return nil end
    if M.is_tbl_root(node) then return node end
  end
end

---Returns `true` if the provided node is a table cell, and `false` otherwise.
function M.is_tbl_cell(node)
  local type = node:type()
  return type == tbl_cell or type == tbl_delimiter_cell
end

---Returns `true` if the provided node is a table row, and `false` otherwise.
function M.is_tbl_row(node)
  local type = node:type()
  return type == tbl_header or type == tbl_delimiter_row or type == tbl_row
end

---Returns `true` if the provided node is an alignment node, and `false` otherwise.
function M.is_tbl_align(node)
  local type = node:type()
  return type == tbl_align_left or type == tbl_align_right
end

---Returns rows for a new table that is not surrounded by pipes.
---@return string[]
function M.gen_table_alt()
  local padd             = conf.get_config().padd_column_separators
  local column_separator = padd and ' | ' or '|'

  local header_row       = { 'Column1', column_separator, 'Column2' }
  local delimiter_row    = { '-------', column_separator, '-------' }
  local row              = { 'x      ', column_separator, 'x' }

  return {
    table.concat(header_row),
    table.concat(delimiter_row),
    table.concat(row),
  }
end

---Returns rows for a new table.
---@return string[]
function M.gen_table()
  local padd            = conf.get_config().padd_column_separators
  local first_separator = padd and '| ' or '|'
  local last_separator  = padd and ' |' or '|'
  local separator       = padd and ' | ' or '|'

  local header_row      = { first_separator, 'Column1', separator, 'Column2', last_separator }
  local delimiter_row   = { first_separator, '-------', separator, '-------', last_separator }
  local row             = { first_separator, 'x      ', separator, 'x      ', last_separator }

  return {
    table.concat(header_row),
    table.concat(delimiter_row),
    table.concat(row),
  }
end

---Iterate of all children of a treesitter node.
---@param node TSNode
---@return fun(): integer?, TSNode?
function M.iter_children(node)
  local n = node:child_count()
  local i = -1
  return function()
    i = i + 1
    if i < n then return i + 1, node:child(i) end
  end
end

---Iterate of all named children of a treesitter node.
---@param node TSNode
---@return fun(): integer?, TSNode?
function M.iter_named_children(node)
  local n = node:named_child_count()
  local i = -1
  return function()
    i = i + 1
    if i < n then return i + 1, node:named_child(i) end
  end
end

--- Get next or previous sibling of a table node
---@param node TSNode
---@return TSNode?
function M.tbl_named_sibling(node, next)
  while true do
    ---@diagnostic disable-next-line: cast-local-type
    node = next and node:next_named_sibling() or node:prev_named_sibling()
    if not node then return end
    if M.is_tbl_node(node) then return node end
  end
end

return M
