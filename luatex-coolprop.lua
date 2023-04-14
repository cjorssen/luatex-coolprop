LTCP = LTCP or {}

local tex_sprint = tex.sprint

function LTCP.error(string_error)
   tex_sprint('\\csname LTCP@error\\endcsname{' .. string_error .. '}')
end


-- luatex-coolprop relies on FFI lua library (http://luajit.org/ext_ffi.html)
local ffi = require('ffi')
local ffi_load = ffi.load
local ffi_cdef = ffi.cdef
local ffi_typeof = ffi.typeof
local ffi_new = ffi.new
local ffi_string = ffi.string

local pcall = pcall

local status, CPlib = pcall(ffi_load, '/home/christophe/git/CoolProp/build/libCoolProp')

if not status then
   -- If CoolProp loading failed, then libCP is a string with the error message
   LTCP.error('luatex-coolprop cannot find CoolProp library on your system.^^JThis is what Lua says:^^J' .. CPlib)
end

-- C declarations for the functions in coolprop library (adapted from https://github.com/CoolProp/CoolProp/blob/master/include/CoolPropLib.h).
-- Note for the lua newbie. [[<literal string>]] is a long format of a literal string in lua: no interpretation of escape sequence and any kind of EOF sequence is converted to a simple new line. See https://www.lua.org/manual/5.4/manual.html#3.1.
ffi_cdef([[
double Props1SI(const char *FluidName, const char* Output);
double PropsSI(const char *Output, const char *Name1, double Prop1, const char *Name2, double Prop2, const char *Ref);
long get_global_param_string(const char *param, char *Output, int n);
]])

-- Lua equivalents to C strings for library outputs
-- VLA — A variable-length array is declared with a ? instead of the number of elements, e.g. "int[?]". The number of elements (nelem) must be given when it's created (see https://luajit.org/ext_ffi_api.html)
local Cstring = ffi_typeof('char[?]')
local SHORT_CSTRING_LEN = 256
local short_Cstring = ffi_new(Cstring, SHORT_CSTRING_LEN)
local LONG_CSTRING_LEN = 4096
local long_Cstring = ffi_new(Cstring, LONG_CSTRING_LEN)

-- Naming conventions
-- * LTCP._<name_of_the_function_in_CoolProp>: returned value is the same as in the library with error managment at TeX level
-- * LTCP.<name_of_the_function_in_CoolProp>: returned value is tex.sprint'ed (and possibly reformatted)

function LTCP._get_global_param_string(string_param)
   if CPlib.get_global_param_string(string_param, long_Cstring, LONG_CSTRING_LEN) == 1 then
      return ffi_string(long_Cstring)
   end
   LTCP.error('Something went wrong with CoolProp.get_global_param_string("' .. string_param .. '")')
   return ''
end

function LTCP._get_errstring()
   return LTCP._get_global_param_string('errstring')
end

function LTCP.get_errstring()
   return tex_sprint(LTCP._get_errstring())
end

local string_gmatch = string.gmatch
local table_insert = table.insert
local table_sort = table.sort
local table_concat = table.concat

function LTCP._get_FluidsList()
   return LTCP._get_global_param_string('FluidsList')
end

function LTCP.get_FluidsList()
   -- Returns the list of fluids as a "list" of comma separated values.
   -- We sort the fluid names alphabetically (that is not done by CoolProp).
   local FluidsTable = {}
   local FluidsList = LTCP._get_FluidsList()
   for Fluid in string_gmatch(FluidsList, '[^,]+') do
      table_insert(FluidsTable, Fluid)
   end
   table_sort(FluidsTable)
   FluidsList = table_concat(FluidsTable, ', ')
   return tex_sprint(FluidsList)
end

function LTCP._get_version()
   return LTCP._get_global_param_string('version')
end

function LTCP.get_version()
   return tex_sprint(LTCP._get_version())
end

function LTCP._get_gitrevision()
   return LTCP._get_global_param_string('gitrevision')
end

function LTCP.get_gitrevision()
   return tex_sprint(LTCP._get_gitrevision())
end

local huge = math.huge

function LTCP._Props1SI(string_FluidName, string_Output)
   -- See http://coolprop.org/coolprop/HighLevelAPI.html#table-of-string-inputs-to-propssi-function
   -- Trivial must be True
   local value = CPlib.Props1SI(string_FluidName, string_Output)
   if value == huge then
      LTCP.error('Something went wrong with CoolProp.Props1SI("' .. string_FluidName .. '", "' .. string_Output .. '").^^JThis is the errstring message:^^J' .. LTCP._get_errstring())
      return 0
   end
   return value
end

function LTCP.Props1SI(string_FluidName, string_Output)
   return tex_sprint(LTCP._Props1SI(string_FluidName, string_Output))
end

function LTCP._PropsSI(string_Output, string_Name1, double_Prop1, string_Name2, double_Prop2, string_Ref)
   -- See http://coolprop.org/coolprop/HighLevelAPI.html#table-of-string-inputs-to-propssi-function
   local value = CPlib.PropsSI(string_Output, string_Name1, double_Prop1, string_Name2, double_Prop2, string_Ref)
   if value == huge then
      LTCP.error('Something went wrong with CoolProp.PropsSI("' .. string_FluidName .. '", "' .. string_Output .. '").^^JThis is the errstring message:^^J' .. LTCP._get_errstring())
      return 0
   end
   return value
end

function LTCP.PropsSI(string_Output, string_Name1, double_Prop1, string_Name2, double_Prop2, string_Ref)
   return tex_sprint(LTCP._PropsSI(string_Output, string_Name1, double_Prop1, string_Name2, double_Prop2, string_Ref))
end
