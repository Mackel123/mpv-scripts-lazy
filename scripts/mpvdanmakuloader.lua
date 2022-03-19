local mp = {}
setmetatable(mp, {
    __index = function(tbl, name)
        local ret = _G["mp"][name] or rawget(tbl, name)
        if ret
        then
            return ret
        end

        if name == "msg"
        then
            ret = require("mp.msg")
        elseif name == "options"
        then
            ret = require("mp.options")
        elseif name == "utils"
        then
            ret = require("mp.utils")
        else
            return ret
        end

        tbl[name] = ret
        return ret
    end,
})


local require = nil
local __loadedModules = {}
require = function(path)

    if path == "src/base/_algo"
    then
        local requestedModule = __loadedModules[path]
        if not requestedModule
        then
            local function src_base__algo_lua()


-------------------------- src/base/_algo.lua <START> --------------------------
local types     = require("src/base/types")
local constants = require("src/base/constants")


local __gParallelIndexes    = {}
local __gParallelArrayBak   = {}


local function __equals(val1, val2)
    return val1 == val2
end


local function clearTable(tbl)
    if types.isTable(tbl)
    then
        for k, _ in pairs(tbl)
        do
            tbl[k] = nil
        end
    end
    return tbl
end


local function clearArray(array, startIdx, endIdx)
    if types.isTable(array)
    then
        startIdx = startIdx or 1
        endIdx = endIdx or #array
        for i = startIdx, endIdx
        do
            array[i] = nil
        end
    end
    return array
end


local function mergeTable(destTbl, srcTbl, ignoreExisted)
    if types.isTable(destTbl) and types.isTable(srcTbl)
    then
        for k, v in pairs(srcTbl)
        do
            destTbl[k] = ignoreExisted and destTbl[k] or v
        end
    end
    return destTbl
end


local function appendArrayElementsIf(destArray, srcArray, filterFunc, arg)
    if types.isTable(destArray) and types.isTable(srcArray)
    then
        for _, v in ipairs(srcArray)
        do
            if not filterFunc or filterFunc(v, arg)
            then
                table.insert(destArray, v)
            end
        end
    end
    return destArray
end


local function appendArrayElements(destArray, srcArray)
    return appendArrayElementsIf(destArray, srcArray)
end


local function packArray(array, ...)
    if types.isTable(array)
    then
        for i = 1, types.getVarArgCount(...)
        do
            -- 不要用 table.insert() 因为可能有空洞
            array[i] = select(i, ...)
        end
    end
    return array
end


local function linearSearchArrayIf(array, func, arg)
    if types.isTable(array)
    then
        for idx, v in ipairs(array)
        do
            if func(v, arg)
            then
                return true, idx, v
            end
        end
    end
    return false
end


local function linearSearchArray(array, val)
    return linearSearchArrayIf(array, __equals, val)
end


local function binarySearchArrayIf(list, func, arg)
    if not types.isTable(list) or not types.isFunction(func)
    then
        return false
    end

    local low = 1
    local high = #list
    while low <= high
    do
        local mid = math.floor((low + high) / 2)
        local midVal = list[mid]
        local cmpRet = func(list[mid], arg)

        if cmpRet == 0
        then
            return true, mid, midVal
        elseif cmpRet > 0
        then
            high = mid - 1
        else
            low = mid + 1
        end
    end

    -- 找不到返回的是插入位置
    return false, low, nil
end


local function iteratePairsArray(array, startIdx)
    local function __doIteratePairsArray(array, idx)
        local nextIdx = idx and idx + 2 or 1
        if nextIdx > #array
        then
            return nil
        end

        return nextIdx, array[nextIdx], array[nextIdx + 1]
    end

    if not types.isTable(array)
    then
        return constants.FUNC_EMPTY
    end
    return __doIteratePairsArray, array, startIdx
end


local function fillArrayWithAscNumbers(array, count)
    for i = 1, count
    do
        array[i] = i
    end
    clearArray(array, count + 1)
end


local function reverseArray(array, startIdx, lastIdx)
    if types.isTable(array)
    then
        startIdx = startIdx or 1
        lastIdx = lastIdx or #array
        while startIdx < lastIdx
        do
            local lowVal = array[startIdx]
            local highVal = array[lastIdx]
            array[startIdx] = lowVal
            array[lastIdx] = highVal
            startIdx = startIdx + 1
            lastIdx = lastIdx - 1
        end
    end
end


local function sortParallelArrays(...)
    local function __reorderArray(indexes, array, arrayBak)
        for i = 1, #indexes
        do
            arrayBak[i] = array[i]
        end

        for i = 1, #indexes
        do
            array[i] = arrayBak[indexes[i]]
        end
    end


    if types.isEmptyVarArgs(...)
    then
        return
    end

    -- 允许第一个参数是比较函数
    local firstArg = select(1, ...)
    local hasCompareFunc = types.isFunction(firstArg)
    local compareFunc = hasCompareFunc and firstArg
    local arrayStartIdx = 1 + types.toNumber(hasCompareFunc)

    -- 以第一个数组内容作为排序关键词
    local firstArray = select(arrayStartIdx, ...)
    if not firstArray
    then
        return
    end

    local compareFuncArg = nil
    if hasCompareFunc
    then
        compareFuncArg = function(idx1, idx2)
            return compareFunc(firstArray[idx1], firstArray[idx2])
        end
    else
        compareFuncArg = function(idx1, idx2)
            return firstArray[idx1] < firstArray[idx2]
        end
    end

    -- 获取排序后的新位置
    local indexes = clearTable(__gParallelIndexes)
    fillArrayWithAscNumbers(indexes, #firstArray)
    table.sort(indexes, compareFuncArg)


    -- 调整位置
    local arrayBak = clearTable(__gParallelArrayBak)
    for i = arrayStartIdx, types.getVarArgCount(...)
    do
        __reorderArray(indexes, select(i, ...), arrayBak)
        clearTable(arrayBak)
    end

    clearTable(indexes)

    indexes = nil
    arrayBak = nil
    compareFuncArg = nil
end


local function reverseIterateArray(array)
    local function __doReverseIterateArrayImpl(array, idx)
        idx = idx - 1
        if idx < 1
        then
            return nil
        end

        return idx, array[idx]
    end

    if not types.isTable(array)
    then
        return constants.FUNC_EMPTY
    end
    return __doReverseIterateArrayImpl, array, #array + 1
end

local function iterateTable(tbl)
    if not types.isTable(tbl)
    then
        return constants.FUNC_EMPTY
    end
    return pairs(tbl)
end

local function iterateArray(array)
    if not types.isTable(array)
    then
        return constants.FUNC_EMPTY
    end
    return ipairs(array)
end

local function popArrayElement(array)
    if types.isTable(array)
    then
        local count = #array
        local ret = array[count]
        array[count] = nil
        return ret
    end
end

local function pushArrayElement(array, elem)
    if types.isTable(array) and not types.isNil(elem)
    then
        table.insert(array, elem)
    end
end


local function removeArrayElementsIf(array, func, arg)
    if types.isTable(array)
    then
        local writeIdx = 1
        for i, element in ipairs(array)
        do
            if not func(element, arg)
            then
                array[writeIdx] = element
                writeIdx = writeIdx + 1
            end
        end
        clearArray(array, writeIdx)
    end
end

local function removeArrayElements(array, val)
    removeArrayElementsIf(array, __equals, val)
end

local function forEachArrayElement(array, func, arg)
    if types.isFunction(func)
    then
        for i, v in iterateArray(array)
        do
            func(v, i, array, arg)
        end
    end
end

local function forEachTableKey(tbl, func, arg)
    if types.isFunction(func)
    then
        for k, v in iterateTable(tbl)
        do
            func(k, v, tbl, arg)
        end
    end
end

local function forEachTableValue(tbl, func, arg)
    if types.isFunction(func)
    then
        for k, v in iterateTable(tbl)
        do
            func(v, k, tbl, arg)
        end
    end
end


return
{
    clearTable                  = clearTable,
    mergeTable                  = mergeTable,
    clearArray                  = clearArray,
    packArray                   = packArray,
    unpackArray                 = unpack or table.unpack,
    appendArrayElements         = appendArrayElements,
    appendArrayElementsIf       = appendArrayElementsIf,
    removeArrayElements         = removeArrayElements,
    removeArrayElementsIf       = removeArrayElementsIf,
    pushArrayElement            = pushArrayElement,
    popArrayElement             = popArrayElement,
    linearSearchArray           = linearSearchArray,
    linearSearchArrayIf         = linearSearchArrayIf,
    binarySearchArrayIf         = binarySearchArrayIf,
    iterateTable                = iterateTable,
    iterateArray                = iterateArray,
    reverseIterateArray         = reverseIterateArray,
    iteratePairsArray           = iteratePairsArray,
    forEachArrayElement         = forEachArrayElement,
    forEachTableKey             = forEachTableKey,
    forEachTableValue           = forEachTableValue,
    sortParallelArrays          = sortParallelArrays,
    fillArrayWithAscNumbers     = fillArrayWithAscNumbers,
}
--------------------------- src/base/_algo.lua <END> ---------------------------

            end
            requestedModule = src_base__algo_lua()
            __loadedModules[path] = requestedModule
        end
        return requestedModule
    end
    if path == "src/base/_conv"
    then
        local requestedModule = __loadedModules[path]
        if not requestedModule
        then
            local function src_base__conv_lua()


-------------------------- src/base/_conv.lua <START> --------------------------
local utf8      = require("src/base/utf8")
local types     = require("src/base/types")
local constants = require("src/base/constants")


local _XML_ESCAPE_STR_UNICODE_RADIX     = 16
local _XML_ESCAPE_STR_PATTERN           = "(&[lgaq#][^;]*;)"
local _XML_ESCAPE_STR_UNICODE_PATTERN   = "&#x(%x+);"
local _XML_ESCAPE_STR_MAP               =
{
    ["&lt;"]    = "<",
    ["&gt;"]    = ">",
    ["&amp;"]   = "&",
    ["&apos;"]  = "\'",
    ["&quot;"]  = "\"",
}

local function __replaceEscapedXMLText(text)
    -- 转义字符
    local unscaped = _XML_ESCAPE_STR_MAP[text]
    if unscaped
    then
        return unscaped
    end

    -- 也有可能是 unicode
    local matched = text:match(_XML_ESCAPE_STR_UNICODE_PATTERN)
    if matched
    then
        local ret = constants.STR_EMPTY
        local codePoint = tonumber(matched, _XML_ESCAPE_STR_UNICODE_RADIX)
        for _, utf8Byte in utf8.iterateUTF8EncodedBytes(codePoint)
        do
            ret = ret .. string.char(utf8Byte)
        end
        return ret
    end

    -- 不可转义，保持原样
    return nil
end

local function unescapeXMLString(text)
    local str = text:gsub(_XML_ESCAPE_STR_PATTERN, __replaceEscapedXMLText)
    return str
end



local _COLOR_CONV_CHANNEL_MOD   = 256
local _COLOR_CONV_MIN_VALUE     = 0

local function splitARGBHex(num)
    local function __popColorChannel(num)
        local channel = math.floor(num % _COLOR_CONV_CHANNEL_MOD)
        local remaining = math.floor(num / _COLOR_CONV_CHANNEL_MOD)
        return remaining, channel
    end

    local a = _COLOR_CONV_MIN_VALUE
    local r = _COLOR_CONV_MIN_VALUE
    local g = _COLOR_CONV_MIN_VALUE
    local b = _COLOR_CONV_MIN_VALUE
    num = math.max(math.floor(num), _COLOR_CONV_MIN_VALUE)
    num, b = __popColorChannel(num)
    num, g = __popColorChannel(num)
    num, r = __popColorChannel(num)
    num, a = __popColorChannel(num)
    return a, r, g, b
end



local _TIME_CONV_MS_PER_SECOND  = 1000
local _TIME_CONV_MS_PER_MINUTE  = 60 * 1000
local _TIME_CONV_MS_PER_HOUR    = 60 * 60 * 1000

local function convertTimeToHMS(time)
    local hours = math.floor(time / _TIME_CONV_MS_PER_HOUR)

    time = time - hours * _TIME_CONV_MS_PER_HOUR
    local minutes = math.floor(time / _TIME_CONV_MS_PER_MINUTE)

    time = time - minutes * _TIME_CONV_MS_PER_MINUTE
    local seconds = time / _TIME_CONV_MS_PER_SECOND

    return hours, minutes, seconds
end


local function convertHHMMSSToTime(h, m, s, ms)
    local ret = 0
    ret = ret + h * _TIME_CONV_MS_PER_HOUR
    ret = ret + m * _TIME_CONV_MS_PER_MINUTE
    ret = ret + s * _TIME_CONV_MS_PER_SECOND
    ret = ret + (ms or 0)
    return ret
end


local _ASS_ESCAPABLE_CHARS_PATTERN  = "[\n\\{} ]"
local _ASS_ESCAPABLE_CHAR_MAP       =
{
    ["\n"]      = "\\N",
    ["\\"]      = "\\\\",
    ["{"]       = "\\{",
    ["}"]       = "\\}",
    [" "]       = "\\h",
}

local function escapeASSString(text)
    local str = text:gsub(_ASS_ESCAPABLE_CHARS_PATTERN, _ASS_ESCAPABLE_CHAR_MAP)
    return str
end




local _JSON_PATTERN_ESCAPABLE_CHARS     = '\\([\\\"/bfnrt])'
local _JSON_PATTERN_ESCAPABLE_UNICODE   = '\\u(%x%x%x%x)'
local _JOSN_PATTERN_NONEMPTY_STRING     = '"(.-[^\\])"'
local _JSON_CONST_STRING_START          = '\"'
local _JSON_CONST_EMPTY_STRING          = '""'
local _JSON_UNICODE_NUMBER_BASE         = 16
local _JSON_SPECIAL_CHAR_MAP            =
{
    ["\""]      = "\"",
    ["\\"]      = "\\",
    ["/"]       = "/",
    ["f"]       = "\f",
    ["b"]       = "",       -- 暂时忽略退格
    ["n"]       = "\n",
    ["t"]       = "\t",
    ["r"]       = "\r",
}

local function unescapeJSONString(text)
    -- 特殊字符转义
    local function __unescapeSpecialChars(captured)
        return _JSON_SPECIAL_CHAR_MAP[captured]
    end

    -- unicode 转义
    local function __unescapeJSONUnicode(captured)
        local hex = tonumber(captured, _JSON_UNICODE_NUMBER_BASE)
        local ret = constants.STR_EMPTY
        for _, utf8Byte in utf8.iterateUTF8EncodedBytes(hex)
        do
            ret = ret .. string.char(utf8Byte)
        end
        return ret
    end

    local ret = text:gsub(_JSON_PATTERN_ESCAPABLE_CHARS, __unescapeSpecialChars)
    ret = ret:gsub(_JSON_PATTERN_ESCAPABLE_UNICODE, __unescapeJSONUnicode)
    return ret
end


local function findJSONString(text, findStartIdx)
    findStartIdx = types.isNumber(findStartIdx) and findStartIdx or 1
    local pos = text:find(_JSON_CONST_STRING_START, findStartIdx, true)
    if pos
    then
        -- 特判空字符串，暂时找不到一个同时匹配空字符串正则表达式囧
        local lastIdx = pos + #_JSON_CONST_EMPTY_STRING - 1
        if text:sub(pos, lastIdx) == _JSON_CONST_EMPTY_STRING
        then
            return constants.STR_EMPTY, lastIdx + 1
        end

        local startIdx, endIdx, captured = text:find(_JOSN_PATTERN_NONEMPTY_STRING, pos)
        if captured
        then
            return unescapeJSONString(captured), endIdx + 1
        end
    end
end



local _URL_ESCAPED_CHAR_FORMAT      = "%%%02X"
local _URL_PATTERN_SPECIAL_CHARS    = "[^A-Za-z0-9%-_%.~]"

local function escapeURLString(text)
    local function __replaceURLSpecialChars(text)
        return string.format(_URL_ESCAPED_CHAR_FORMAT, text:byte(1))
    end
    return text:gsub(_URL_PATTERN_SPECIAL_CHARS, __replaceURLSpecialChars)
end


return
{
    escapeASSString             = escapeASSString,
    unescapeXMLString           = unescapeXMLString,
    escapeURLString             = escapeURLString,
    unescapeJSONString          = unescapeJSONString,
    findJSONString              = findJSONString,
    convertTimeToHMS            = convertTimeToHMS,
    convertHHMMSSToTime         = convertHHMMSSToTime,
    splitARGBHex                = splitARGBHex,
}

--------------------------- src/base/_conv.lua <END> ---------------------------

            end
            requestedModule = src_base__conv_lua()
            __loadedModules[path] = requestedModule
        end
        return requestedModule
    end
    if path == "src/base/classlite"
    then
        local requestedModule = __loadedModules[path]
        if not requestedModule
        then
            local function src_base_classlite_lua()


------------------------ src/base/classlite.lua <START> ------------------------
local types     = require("src/base/types")
local utils     = require("src/base/utils")
local constants = require("src/base/constants")


local _METATABLE_NAME_INDEX             = "__index"

local _METHOD_NAME_CONSTRUCT            = "new"
local _METHOD_NAME_DECONSTRUCT          = "dispose"
local _METHOD_NAME_CLONE                = "clone"
local _METHOD_NAME_RESET                = "reset"
local _METHOD_NAME_GET_CLASS            = "getClass"
local _METHOD_NAME_INIT_FIELDS          = "__classlite_init_fields"
local _METHOD_NAME_DEINIT_FIELDS        = "__classlite_deinit_fields"

local _FIELD_DECL_TYPE_CONSTANT         = 1
local _FIELD_DECL_TYPE_TABLE            = 2
local _FIELD_DECL_TYPE_CLASS            = 3

local _FIELD_DECL_KEY_ID                = {}
local _FIELD_DECL_KEY_TYPE              = 1
local _FIELD_DECL_KEY_FIRST_ARG         = 2
local _FIELD_DECL_KEY_CLASS_ARGS_START  = 3

local _CLASS_INHERIT_LEVEL_START        = 1


local __gMetatables             = {}
local __gParentClasses          = {}
local __gClassInheritLevels     = {}
local __gFieldNames             = {}
local __gFieldDeclarations      = {}
local __gFieldDeclartionID      = 0


local function __invokeInstanceMethod(obj, methodName, ...)
    return utils.invokeSafely(obj[methodName], obj, ...)
end


local function isInstanceOf(obj, clz)
    -- 空指针总会返回 false
    if not types.isTable(obj) or not types.isTable(clz)
    then
        return false
    end

    local objClz = __invokeInstanceMethod(obj, _METHOD_NAME_GET_CLASS)
    if not objClz
    then
        return false
    end

    local objLv = __gClassInheritLevels[objClz]
    local clzLv = __gClassInheritLevels[clz]
    if not objLv or not clzLv
    then
        return false
    end

    local function __traceBackToSameLevel(parentMap, clz1, level1, clz2, level2)
        if level1 > level2
        then
            return __traceBackToSameLevel(parentMap, clz2, level2, clz1, level1)
        end

        while level2 ~= level1
        do
            level2 = level2 - 1
            clz2 = parentMap[clz2]
        end
        return clz1, clz2
    end

    local clz1, clz2 = __traceBackToSameLevel(__gParentClasses, objClz, objLv, clz, clzLv)
    while clz1 and clz2
    do
        if clz1 == clz2
        then
            return true
        end

        clz1 = __gParentClasses[clz1]
        clz2 = __gParentClasses[clz2]
    end
    return false
end


local function __constructConstantField(obj, name, decl)
    local field = decl[_FIELD_DECL_KEY_FIRST_ARG]
    obj[name] = field
    return field
end

local function __constructTableField(obj, name, decl)
    local field = {}
    obj[name] = field
    return field
end

local function __constructClassField(obj, name, decl)
    local classType = decl[_FIELD_DECL_KEY_FIRST_ARG]
    local constructor = classType[_METHOD_NAME_CONSTRUCT]
    local field = constructor(classType,
                              select(_FIELD_DECL_KEY_CLASS_ARGS_START,
                                     utils.unpackArray(decl)))
    obj[name] = field
    return field
end


local _FUNCS_CONSTRUCT =
{
    [_FIELD_DECL_TYPE_CONSTANT] = __constructConstantField,
    [_FIELD_DECL_TYPE_TABLE]    = __constructTableField,
    [_FIELD_DECL_TYPE_CLASS]    = __constructClassField,
}


local _FUNCS_DECONSTRUCT =
{
    [_FIELD_DECL_TYPE_CONSTANT] = function(obj, name, decl)
        obj[name] = nil
    end,

    [_FIELD_DECL_TYPE_TABLE]    = function(obj, name, decl)
        utils.clearTable(obj[name])
        obj[name] = nil
    end,

    [_FIELD_DECL_TYPE_CLASS]    = function(obj, name, decl)
        utils.disposeSafely(obj[name])
        obj[name] = nil
    end,
}


local _FUNCS_CLONE =
{
    [_FIELD_DECL_TYPE_CONSTANT] = function(obj, name, decl, arg)
        obj[name] = arg
    end,

    [_FIELD_DECL_TYPE_TABLE]    = function(obj, name, decl, arg)
        local field = utils.clearTable(obj[name])
        if not field
        then
            field = {}
            obj[name] = field
        end
        utils.appendArrayElements(field, arg)
    end,

    [_FIELD_DECL_TYPE_CLASS]    = function(obj, name, decl, arg)
        local field = obj[name]
        if not field
        then
            field = __constructClassField(obj, name, decl)
        end
        if isInstanceOf(arg, __invokeInstanceMethod(field, _METHOD_NAME_GET_CLASS))
        then
            __invokeInstanceMethod(arg, _METHOD_NAME_CLONE, field)
        end
    end,
}


local _FUNCS_RESET =
{
    [_FIELD_DECL_TYPE_CONSTANT] = __constructConstantField,

    [_FIELD_DECL_TYPE_TABLE]    = function(obj, name, decl)
        local field = obj[name]
        if types.isTable(field)
        then
            utils.clearTable(field)
        else
            __constructTableField(obj, name, decl)
        end
    end,

    [_FIELD_DECL_TYPE_CLASS]    = function(obj, name, decl)
        local field = obj[name]
        local fieldClz = __invokeInstanceMethod(field, _METHOD_NAME_GET_CLASS)
        if isInstanceOf(field, fieldClz)
        then
            __invokeInstanceMethod(field, _METHOD_NAME_RESET)
        else
            __constructClassField(obj, name, decl)
        end
    end,
}


local function __doDeclareField(fieldType, ...)
    local ret = { fieldType, ... }
    ret[_FIELD_DECL_KEY_ID] = __gFieldDeclartionID
    __gFieldDeclartionID = __gFieldDeclartionID + 1
    return ret
end

local function declareConstantField(val)
    return __doDeclareField(_FIELD_DECL_TYPE_CONSTANT, val)
end

local function declareTableField(val)
    return __doDeclareField(_FIELD_DECL_TYPE_TABLE, val)
end

local function declareClassField(classType, ...)
    return __doDeclareField(_FIELD_DECL_TYPE_CLASS, classType, ...)
end


local function _newInstance(obj)
    local mt = obj and __gMetatables[obj]
    if types.isTable(mt)
    then
        -- 如果以 ClazDefObj:new() 的形式调用，第一个参数就是指向 Class 本身
        local ret = {}
        setmetatable(ret, mt)
        return true, ret
    else
        -- 也有可能是子类间接调用父类的构造方法，此时不应再创建实例
        return false, obj
    end
end

local function _disposeInstance(obj)
    if types.isTable(obj)
    then
        utils.clearTable(obj)
        setmetatable(obj, nil)
    end
end


local function __createFielesFunction(names, decls, functionMap)
    if not names or not decls
    then
        return nil
    end

    local ret = function(self, ...)
        for i, name in ipairs(names)
        do
            local decl = decls[i]
            local declType = decl[_FIELD_DECL_KEY_TYPE]
            functionMap[declType](self, name, decl)
        end
    end

    return ret
end


local function _createFieldsConstructor(clzDef)
    local names = __gFieldNames[clzDef]
    local decls = __gFieldDeclarations[clzDef]
    if names and decls
    then
        return __createFielesFunction(names, decls, _FUNCS_CONSTRUCT)
    else
        return constants.FUNC_EMPTY
    end
end


local function _createFieldsDeconstructor(clzDef)
    local names = __gFieldNames[clzDef]
    local decls = __gFieldDeclarations[clzDef]
    if names and decls
    then
        return __createFielesFunction(names, decls, _FUNCS_DECONSTRUCT)
    else
        return constants.FUNC_EMPTY
    end
end


local function _createConstructor(clzDef, names, decls)
    local baseClz = __gParentClasses[clzDef]
    local baseConstructor = baseClz and baseClz[_METHOD_NAME_CONSTRUCT]
    local constructor = clzDef[_METHOD_NAME_CONSTRUCT] or baseConstructor

    local ret = function(self, ...)
        local isNewlyAllocated, obj = _newInstance(self)

        -- 在执行构造方法前，将继承链上所有声明的字段都初始化，只执行一次
        if isNewlyAllocated
        then
            __invokeInstanceMethod(obj, _METHOD_NAME_INIT_FIELDS, ...)
        end

        if constructor
        then
            constructor(obj, ...)
        end

        return obj
    end

    return ret
end


local function _createCloneConstructor(clzDef)
    local fieldNames = __gFieldNames[clzDef]
    local fieldDecls = __gFieldDeclarations[clzDef]
    local baseClz = __gParentClasses[clzDef]
    local baseCloneConstructor = baseClz and baseClz[_METHOD_NAME_CLONE]
    local cloneConstructor = clzDef[_METHOD_NAME_CLONE] or baseCloneConstructor

    local ret = function(self, cloneObj)
        if self == cloneObj
        then
            return self
        end

        local shouldCloneFields = false
        if not cloneObj
        then
            local _, newObj = _newInstance(clzDef)
            cloneObj = newObj
            shouldCloneFields = true
        elseif __invokeInstanceMethod(cloneObj, _METHOD_NAME_GET_CLASS) == clzDef
        then
            shouldCloneFields = true
        end

        -- 深克隆要自己实现
        if shouldCloneFields and fieldNames
        then
            for i = 1, #fieldNames
            do
                local fieldName = fieldNames[i]
                local fieldDecl = fieldDecls[i]
                local declType = fieldDecl[_FIELD_DECL_KEY_TYPE]
                local func = _FUNCS_CLONE[declType]
                if func
                then
                    func(cloneObj, fieldName, fieldDecl, self[fieldName])
                end
            end
        end

        if cloneConstructor
        then
            cloneConstructor(self, cloneObj)
        end

        return cloneObj
    end

    return ret
end


local function _createDeconstructor(clzDef)
    local baseClz = __gParentClasses[clzDef]
    local baseDeconstructor = baseClz and baseClz[_METHOD_NAME_DECONSTRUCT]
    local deconstructor = clzDef[_METHOD_NAME_DECONSTRUCT] or baseDeconstructor

    local ret = function(self)
        -- 有可能没有父类而且没有明确的析构方法
        if deconstructor
        then
            deconstructor(self)
        end

        -- 在父类析构方法体中执行最后的操作
        if not baseClz
        then
            -- 销毁所有字段
            __invokeInstanceMethod(self, _METHOD_NAME_DEINIT_FIELDS)

            -- 销毁整个对象
            _disposeInstance(self)
        end
    end

    return ret
end



local function _createGetClassMethod(clzDef)
    local ret = function(self)
        return clzDef
    end

    return ret
end


local function _createFieldsResetMethod(clzDef)
    local names = __gFieldNames[clzDef]
    local decls = __gFieldDeclarations[clzDef]
    if names and decls
    then
        return __createFielesFunction(names, decls, _FUNCS_RESET)
    else
        return constants.FUNC_EMPTY
    end
end


local function __collectAutoFields(clzDef)
    local names = nil
    local decls = nil
    for name, decl in pairs(clzDef)
    do
        if types.isTable(decl) and decl[_FIELD_DECL_KEY_ID]
        then
            names = names or {}
            decls = decls or {}
            table.insert(names, name)
            table.insert(decls, decl)

            -- 清除标记
            clzDef[name] = nil
        end
    end

    -- 合并父类字体
    local parentClz = __gParentClasses[clzDef]
    local parentFieldNames = parentClz and __gFieldNames[parentClz]
    local parentFieldDecls = parentClz and __gFieldDeclarations[parentClz]
    if parentFieldNames and parentFieldDecls
    then
        names = names or {}
        decls = decls or {}

        -- 注意被覆盖的父类字段
        for i, parentFieldName in ipairs(parentFieldNames)
        do
            if not utils.linearSearchArray(names, parentFieldName)
            then
                table.insert(names, parentFieldName)
                table.insert(decls, parentFieldDecls[i])
            end
        end
    end

    -- 保证初始化序列与定义顺序相同
    local function __cmp(decl1, decl2)
        return (decl1[_FIELD_DECL_KEY_ID] < decl2[_FIELD_DECL_KEY_ID])
    end
    utils.sortParallelArrays(__cmp, decls, names)
    return names, decls
end


local function _initClassMetaData(clzDef, baseClz)
    -- 绑定父类
    __gParentClasses[clzDef] = baseClz

    -- 继承深度
    local parentLevel = baseClz and __gClassInheritLevels[baseClz] or _CLASS_INHERIT_LEVEL_START
    __gClassInheritLevels[clzDef] = 1 + parentLevel

    -- 所有声明的字段
    local names, decls = __collectAutoFields(clzDef)
    if names and decls
    then
        __gFieldNames[clzDef] = names
        __gFieldDeclarations[clzDef] = decls
    end
end


local function _createClassMetatable(clzDef)
    local metatable = {}
    metatable[_METATABLE_NAME_INDEX] = clzDef
    __gMetatables[clzDef] = metatable
end


local function declareClass(clzDef, baseClz)
    _initClassMetaData(clzDef, baseClz)

    clzDef[_METHOD_NAME_INIT_FIELDS]    = _createFieldsConstructor(clzDef)
    clzDef[_METHOD_NAME_DEINIT_FIELDS]  = _createFieldsDeconstructor(clzDef)
    clzDef[_METHOD_NAME_CONSTRUCT]      = _createConstructor(clzDef)
    clzDef[_METHOD_NAME_CLONE]          = _createCloneConstructor(clzDef)
    clzDef[_METHOD_NAME_RESET]          = _createFieldsResetMethod(clzDef)
    clzDef[_METHOD_NAME_DECONSTRUCT]    = _createDeconstructor(clzDef)
    clzDef[_METHOD_NAME_GET_CLASS]      = _createGetClassMethod(clzDef)

    utils.mergeTable(clzDef, baseClz, true)
    _createClassMetatable(clzDef)
end


return
{
    declareClass                = declareClass,
    declareConstantField        = declareConstantField,
    declareTableField           = declareTableField,
    declareClassField           = declareClassField,
    isInstanceOf                = isInstanceOf,
}
------------------------- src/base/classlite.lua <END> -------------------------

            end
            requestedModule = src_base_classlite_lua()
            __loadedModules[path] = requestedModule
        end
        return requestedModule
    end
    if path == "src/base/constants"
    then
        local requestedModule = __loadedModules[path]
        if not requestedModule
        then
            local function src_base_constants_lua()


------------------------ src/base/constants.lua <START> ------------------------
return
{
    LUA_VERSION                 = tonumber(_VERSION:match("(%d+%.%d)") or 5),

    FILE_MODE_READ              = "r",
    FILE_MODE_WRITE_ERASE       = "w",
    FILE_MODE_WRITE_APPEND      = "a",
    FILE_MODE_UPDATE            = "r+",
    FILE_MODE_UPDATE_ERASE      = "w+",
    FILE_MODE_UPDATE_APPEND     = "a+",

    READ_MODE_NUMBER            = "*n",
    READ_MODE_ALL               = "*a",
    READ_MODE_LINE_NO_EOL       = "*l",
    READ_MODE_LINE_WITH_EOL     = "*L",

    SEEK_MODE_BEGIN             = "set",
    SEEK_MODE_CURRENT           = "cur",
    SEEK_MODE_END               = "end",

    VBUF_MODE_NO                = "no",
    VBUF_MODE_FULL              = "full",
    VBUF_MODE_LINE              = "line",

    LOAD_MODE_BINARY            = "b",
    LOAD_MODE_CHUNKS            = "t",
    LOAD_MODE_BINARY_CHUNKS     = "bt",

    EXEC_RET_EXIT               = "exit",
    EXEC_RET_SIGNAL             = "signal",

    STR_EMPTY                   = "",
    STR_SPACE                   = " ",
    STR_NEWLINE                 = "\n",
    STR_CARRIAGE_RETURN         = "\r",
    CODEPOINT_NEWLINE           = string.byte("\n"),

    FUNC_EMPTY                  = function() end,
}
------------------------- src/base/constants.lua <END> -------------------------

            end
            requestedModule = src_base_constants_lua()
            __loadedModules[path] = requestedModule
        end
        return requestedModule
    end
    if path == "src/base/serialize"
    then
        local requestedModule = __loadedModules[path]
        if not requestedModule
        then
            local function src_base_serialize_lua()


------------------------ src/base/serialize.lua <START> ------------------------
local types     = require("src/base/types")
local utils     = require("src/base/utils")
local constants = require("src/base/constants")


local _SERIALIZE_FUNC_NAME                  = "_"
local _SERIALIZE_FUNC_START                 = "("
local _SERIALIZE_FUNC_END                   = ")"
local _SERIALIZE_TABLE_START                = "{"
local _SERIALiZE_TABLE_END                  = "}"
local _SERIALIZE_SEP_ARG                    = ", "
local _SERIALIZE_SEP_LINE                   = "\n"
local _SERIALIZE_QUOTE_STRING_FORMAT        = "%q"
local _SERIALIZE_CONST_NIL                  = "nil"


local function _doSerialize(isArray, file, ...)
    if not types.isOpenedFile(file)
    then
        return
    end

    local array = isArray and select(1, ...)
    if isArray and not types.isTable(array)
    then
        return
    end

    file:write(_SERIALIZE_FUNC_NAME)
    file:write(_SERIALIZE_FUNC_START)

    local n = isArray and #array or types.getVarArgCount(...) + 1
    for i = 1, n
    do
        -- 不要用三目运算，迭代值可能是 false / nil
        local elem = nil
        if isArray
        then
            elem = array[i]
        else
            elem = select(i, ...)
        end

        if types.isString(elem)
        then
            file:write(string.format(_SERIALIZE_QUOTE_STRING_FORMAT, elem))
        elseif types.isNumber(elem) or types.isBoolean(elem) or types.isNil(elem)
        then
            file:write(tostring(elem))
        else
            -- 暂时不支持复杂的数据类型
        end

        if i ~= n
        then
            file:write(_SERIALIZE_SEP_ARG)
        end
    end

    file:write(_SERIALIZE_FUNC_END)
    file:write(_SERIALIZE_SEP_LINE)
end


local function serializeArray(file, array)
    return _doSerialize(true, file, array)
end

local function serializeVarArgs(file, ...)
    return _doSerialize(false, file, ...)
end


local function __doDeserialize(input, isFilePath, callback)
    local loadEnv = { [_SERIALIZE_FUNC_NAME] = callback }
    local compiledChunks = isFilePath
                           and loadfile(input, constants.LOAD_MODE_CHUNKS, loadEnv)
                           or load(input, nil, constants.LOAD_MODE_CHUNKS, loadEnv)

    if compiledChunks
    then
        pcall(compiledChunks)
    end

    loadEnv = nil
    compiledChunks = nil
end


local function deserializeFromFilePath(filePath, callback)
    return types.isString(filePath) and __doDeserialize(filePath, true, callback)
end

local function deserializeFromString(chunks, callback)
    return types.isString(chunks) and __doDeserialize(chunks, false, callback)
end


return
{
    serializeVarArgs            = serializeVarArgs,
    serializeArray              = serializeArray,
    deserializeFromFilePath     = deserializeFromFilePath,
    deserializeFromString       = deserializeFromString,
}
------------------------- src/base/serialize.lua <END> -------------------------

            end
            requestedModule = src_base_serialize_lua()
            __loadedModules[path] = requestedModule
        end
        return requestedModule
    end
    if path == "src/base/types"
    then
        local requestedModule = __loadedModules[path]
        if not requestedModule
        then
            local function src_base_types_lua()


-------------------------- src/base/types.lua <START> --------------------------
local constants     = require("src/base/constants")


local _LUA_TYPE_FUNCTION    = "function"
local _LUA_TYPE_TABLE       = "table"
local _LUA_TYPE_STRING      = "string"
local _LUA_TYPE_NUMBER      = "number"
local _LUA_TYPE_BOOLEAN     = "boolean"
local _LUA_TYPE_NIL         = "nil"

local function isString(obj)
    return type(obj) == _LUA_TYPE_STRING
end

local function isNumber(obj)
    return type(obj) == _LUA_TYPE_NUMBER
end

local function isPositiveNumber(obj)
    return isNumber(obj) and obj > 0
end

local function isNonNegativeNumber(obj)
    return isNumber(obj) and obj >= 0
end

local function isBoolean(obj)
    return type(obj) == _LUA_TYPE_BOOLEAN
end

local function isNil(obj)
    return type(obj) == _LUA_TYPE_NIL
end

local function isFunction(obj)
    return type(obj) == _LUA_TYPE_FUNCTION
end

local function isTable(obj)
    return type(obj) == _LUA_TYPE_TABLE
end


local _IO_TYPE_OPENED_FILE  = "file"
local _IO_TYPE_CLOSED_FILE  = "closed file"

local function isOpenedFile(obj)
    return io.type(obj) == _IO_TYPE_OPENED_FILE
end

local function isClosedFile(obj)
    return io.type(obj) == _IO_TYPE_CLOSED_FILE
end


local function isEmptyTable(obj)
    return (isTable(obj) and next(obj) == nil)
end

local function isNilOrEmpty(obj)
    return (obj == nil or obj == constants.STR_EMPTY or isEmptyTable(obj))
end

local function getVarArgCount(...)
    return select("#", ...)
end

local function isEmptyVarArgs(...)
    return (getVarArgCount(...) == 0)
end

local function toNumber(obj)
    if not obj
    then
        return 0
    elseif isNumber(obj)
    then
        return obj
    else
        return 1
    end
end

local function toBoolean(obj)
    return obj and true or false
end


local function getStringWithDefault(str, default)
    return isString(str) and str or default
end

local function getNumberWithDefault(num, default)
    return isNumber(num) and num or default
end


return
{
    isString                = isString,
    isNumber                = isNumber,
    isPositiveNumber        = isPositiveNumber,
    isNonNegativeNumber     = isNonNegativeNumber,
    isBoolean               = isBoolean,
    isNil                   = isNil,
    isFunction              = isFunction,
    isTable                 = isTable,
    isOpenedFile            = isOpenedFile,
    isClosedFile            = isClosedFile,
    isNilOrEmpty            = isNilOrEmpty,
    isEmptyTable            = isEmptyTable,
    isEmptyVarArgs          = isEmptyVarArgs,
    getVarArgCount          = getVarArgCount,
    toNumber                = toNumber,
    toBoolean               = toBoolean,
    getStringWithDefault    = getStringWithDefault,
    getNumberWithDefault    = getNumberWithDefault,
}
--------------------------- src/base/types.lua <END> ---------------------------

            end
            requestedModule = src_base_types_lua()
            __loadedModules[path] = requestedModule
        end
        return requestedModule
    end
    if path == "src/base/unportable"
    then
        local requestedModule = __loadedModules[path]
        if not requestedModule
        then
            local function src_base_unportable_lua()


----------------------- src/base/unportable.lua <START> ------------------------
local types     = require("src/base/types")
local utils     = require("src/base/utils")
local constants = require("src/base/constants")
local classlite = require("src/base/classlite")


local _SHELL_SYNTAX_PIPE_STDOUT_TO_INPUT        = "|"
local _SHELL_SYNTAX_ARGUMENT_SEP                = " "
local _SHELL_SYNTAX_STRONG_QUOTE                = "\'"
local _SHELL_SYNTAX_NO_STDERR                   = "2>/dev/null"
local _SHELL_SYNTAX_REDICT_STDIN                = "<"

local _SHELL_CONST_STRONG_QUOTE_ESCAPED         = "'\"'\"'"
local _SHELL_CONST_DOUBLE_DASH                  = "--"
local _SHELL_CONST_RETURN_CODE_SUCCEED          = 0

local _SHELL_PATTERN_STARTS_WITH_DASH           = "^%-"


local __gCommandArguments   = {}
local __gPathElements1      = {}
local __gPathElements2      = {}


-- 从 pipes.py 抄过来的
local function __quoteShellString(text)
    text = tostring(text)
    local replaced = text:gsub(_SHELL_SYNTAX_STRONG_QUOTE,
                               _SHELL_CONST_STRONG_QUOTE_ESCAPED)
    return _SHELL_SYNTAX_STRONG_QUOTE
           .. replaced
           .. _SHELL_SYNTAX_STRONG_QUOTE
end


local function __addRawArgument(arguments, arg)
    -- 排除 boolean 是因为懒得写 "cond and true_val or nil"
    -- 而且类似 --arg true 参数也很少见
    if types.isString(arg) or types.isNumber(arg)
    then
        table.insert(arguments, tostring(arg))
    end
end

local function _addOption(arguments, arg)
    __addRawArgument(arguments, arg)
end

local function _addCommand(arguments, cmd)
    __addRawArgument(arguments, cmd)
end

local function _addSyntax(arguments, syntax)
    __addRawArgument(arguments, syntax)
end

local function _addValue(arguments, val)
    if types.isString(val) or types.isNumber(val)
    then
        -- 标准命令行中，为了避免值与选项混淆，如果带 - 号还要加一个 -- 来转义
        val = tostring(val)
        if val:match(_SHELL_PATTERN_STARTS_WITH_DASH)
        then
            table.insert(arguments, _SHELL_CONST_DOUBLE_DASH)
        end
        table.insert(arguments, __quoteShellString(val))
    end
end

local function _addOptionAndValue(arguments, optionName, val)
    if optionName and val
    then
        _addOption(arguments, optionName)
        _addValue(arguments, val)
    end
end

local function _getCommandString(arguments)
    return table.concat(arguments, _SHELL_SYNTAX_ARGUMENT_SEP)
end

local function _getCommandResult(arguments, expectedRetCode)
    expectedRetCode = expectedRetCode or _SHELL_CONST_RETURN_CODE_SUCCEED
    local popenFile = io.popen(_getCommandString(arguments))
    local output, succeed, reason, retCode = utils.readAndCloseFile(popenFile)
    local ret = succeed
                and reason == constants.EXEC_RET_EXIT
                and retCode == expectedRetCode
    return ret, output
end


local _PATH_SEPERATOR                   = "/"
local _PATH_ROOT_DIR                    = "/"
local _PATH_CURRENT_DIR                 = "."
local _PATH_PARENT_DIR                  = ".."
local _PATH_PATTERN_ELEMENT             = "[^/]+"
local _PATH_PATTERN_STARTS_WITH_ROOT    = "^/"


local function __splitPathElements(fullPath, paths)
    utils.clearTable(paths)

    if not types.isString(fullPath)
    then
        return false
    end

    -- 将 / 作为单独的路径
    if fullPath:match(_PATH_PATTERN_STARTS_WITH_ROOT)
    then
        table.insert(paths, _PATH_ROOT_DIR)
    end

    for path in fullPath:gmatch(_PATH_PATTERN_ELEMENT)
    do
        if path == _PATH_PARENT_DIR
        then
            local pathCount = #paths
            local lastPathElement = paths[pathCount]
            if not lastPathElement or lastPathElement == _PATH_PARENT_DIR
            then
                table.insert(paths, _PATH_PARENT_DIR)
            elseif lastPathElement == _PATH_ROOT_DIR
            then
                -- 不允许用 .. 将 / 弹出栈，例如 "/../../a" 实际指的是 "/"
            else
                paths[pathCount] = nil
            end
        elseif path == _PATH_CURRENT_DIR
        then
            -- 指向当前文件夹
        else
            table.insert(paths, path)
        end
    end
    return true
end


local function __joinPathElements(paths)
    -- 路径退栈
    local writeIdx = 1
    for i, path in ipairs(paths)
    do
        local insertPath = nil
        if path == _PATH_CURRENT_DIR
        then
            -- ingore
        elseif path == _PATH_PARENT_DIR
        then
            if writeIdx == 1 or paths[writeIdx - 1] == _PATH_PARENT_DIR
            then
                insertPath = _PATH_PARENT_DIR
            else
                writeIdx = writeIdx - 1
            end
        else
            insertPath = path
        end

        if insertPath
        then
            paths[writeIdx] = insertPath
            writeIdx = writeIdx + 1
        end
    end
    utils.clearArray(paths, writeIdx)

    local ret = nil
    if paths[1] == _PATH_ROOT_DIR
    then
        local trailing = table.concat(paths, _PATH_SEPERATOR, 2)
        ret = _PATH_ROOT_DIR .. trailing
    else
        ret = table.concat(paths, _PATH_SEPERATOR)
    end
    utils.clearTable(paths)
    return ret
end



local PathElementIterator =
{
    _mTablePool     = classlite.declareTableField(),
    _mIterateFunc   = classlite.declareConstantField(),

    new = function(self)
        self._mIterateFunc = function(paths, idx)
            idx = idx + 1
            if idx > #paths
            then
                -- 如果是中途 break 出来，就让虚拟机回收吧
                self:_recycleTable(paths)
                return nil
            else
                return idx, paths[idx]
            end
        end
    end,

    _obtainTable = function(self)
        return utils.popArrayElement(self._mTablePool) or {}
    end,

    _recycleTable = function(self, tbl)
        local pool = self._mTablePool
        if types.isTable(pool)
        then
            utils.clearTable(tbl)
            table.insert(pool, tbl)
        end
    end,

    iterate = function(self, fullPath)
        local paths = self:_obtainTable()
        if __splitPathElements(fullPath, paths)
        then
            return self._mIterateFunc, paths, 0
        else
            self:_recycleTable(paths)
            return constants.FUNC_EMPTY
        end
    end,
}

classlite.declareClass(PathElementIterator)


local function normalizePath(fullPath)
    local paths = utils.clearTable(__gPathElements1)
    local succeed = __splitPathElements(fullPath, paths)
    local ret = succeed and __joinPathElements(paths)
    utils.clearTable(paths)
    return ret
end


local function joinPath(dirName, pathName)
    local ret = nil
    if types.isString(dirName) and types.isString(pathName)
    then
        local paths = utils.clearTable(__gPathElements1)
        local fullPath = dirName .. _PATH_SEPERATOR .. pathName
        if __splitPathElements(fullPath, paths)
        then
            ret = __joinPathElements(paths)
        end
        utils.clearTable(paths)
    end

    return ret
end


local function splitPath(fullPath)
    local baseName = nil
    local dirName = nil
    local paths = utils.clearTable(__gPathElements1)
    local succeed = __splitPathElements(fullPath, paths)
    if succeed
    then
        baseName = utils.popArrayElement(paths)
        dirName = __joinPathElements(paths)
    end

    utils.clearTable(paths)
    return dirName, baseName
end


local function getRelativePath(dir, fullPath)
    local ret = nil
    local paths1 = utils.clearTable(__gPathElements1)
    local paths2 = utils.clearTable(__gPathElements2)
    local succeed1 = __splitPathElements(dir, paths1)
    local succeed2 = __splitPathElements(fullPath, paths2)
    if succeed1 and succeed2 and #paths1 > 0 and #paths2 > 0
    then
        -- 找出第一个不同的路径元素
        local paths1Count = #paths1
        local relIdx = paths1Count + 1
        for i = 1, paths1Count
        do
            local comparePath = paths2[i]
            if comparePath and paths1[i] ~= comparePath
            then
                relIdx = i
                break
            end
        end

        -- 有可能两个路径是一样的，提前特判
        local paths2Count = #paths2
        if paths1Count == paths2Count and relIdx > paths1Count
        then
            return _PATH_CURRENT_DIR
        end

        -- 前缀不一定完全匹配的，例如 /1 相对于 /a/b/c/d 路径是 ../../../../1
        local outPaths = utils.clearTable(paths1)
        local parentDirCount = paths1Count - relIdx + 1
        for i = 1, parentDirCount
        do
            table.insert(outPaths, _PATH_PARENT_DIR)
        end

        for i = relIdx, #paths2
        do
            table.insert(outPaths, paths2[i])
        end
        ret = __joinPathElements(outPaths)
    end

    utils.clearTable(paths1)
    utils.clearTable(paths2)
    return ret
end


local _WidgetPropertiesBase =
{
    windowTitle     = classlite.declareConstantField(nil),
    windowWidth     = classlite.declareConstantField(nil),
    windowHeight    = classlite.declareConstantField(nil),
}

classlite.declareClass(_WidgetPropertiesBase)


local TextInfoProperties = {}
classlite.declareClass(TextInfoProperties, _WidgetPropertiesBase)


local EntryProperties =
{
    entryTitle      = classlite.declareConstantField(nil),  -- 提示信息
    entryText       = classlite.declareConstantField(nil),  -- 输入框内容
}

classlite.declareClass(EntryProperties, _WidgetPropertiesBase)


local ListBoxProperties =
{
    isMultiSelectable   = classlite.declareConstantField(false),
    isHeaderHidden      = classlite.declareConstantField(false),
    listBoxTitle        = classlite.declareConstantField(nil),
    listBoxColumnCount  = classlite.declareConstantField(0),
    listBoxHeaders      = classlite.declareTableField(),
    listBoxElements     = classlite.declareTableField(),
}

classlite.declareClass(ListBoxProperties, _WidgetPropertiesBase)


local FileSelectionProperties =
{
    isMultiSelectable   = classlite.declareConstantField(false),
    isDirectoryOnly     = classlite.declareConstantField(false),
}

classlite.declareClass(FileSelectionProperties, _WidgetPropertiesBase)


local ProgressBarProperties =
{
    isAutoClose     = classlite.declareConstantField(false),
}

classlite.declareClass(ProgressBarProperties, _WidgetPropertiesBase)


local QuestionProperties =
{
    questionText    = classlite.declareConstantField(nil),
    labelTextOK     = classlite.declareConstantField(nil),
    labelTextCancel = classlite.declareConstantField(nil),
}

classlite.declareClass(QuestionProperties, _WidgetPropertiesBase)


local _ZENITY_RESULT_RSTRIP_COUNT       = 2
local _ZENITY_DEFAULT_OUTPUT            = constants.STR_EMPTY
local _ZENITY_SEP_LISTBOX_INDEX         = "|"
local _ZENITY_SEP_FILE_SELECTION        = "//.//"
local _ZENITY_PATTERN_SPLIT_INDEXES     = "(%d+)"
local _ZENITY_PREFFIX_PROGRESS_MESSAGE  = "# "

local ZenityGUIBuilder =
{
    __mArguments    = classlite.declareTableField(),

    __prepareZenityCommand = function(self, arguments, props)
        utils.clearTable(arguments)
        _addCommand(arguments, "zenity")
        _addOptionAndValue(arguments, "--title", props.windowTitle)
        _addOptionAndValue(arguments, "--width", props.windowWidth)
        _addOptionAndValue(arguments, "--height", props.windowHeight)
    end,

    _getZenityCommandResult = function(self, arguments)
        _addSyntax(arguments, _SHELL_SYNTAX_NO_STDERR)
        local succeed, output = _getCommandResult(arguments)
        return succeed and output:sub(1, -_ZENITY_RESULT_RSTRIP_COUNT)
    end,


    showTextInfo = function(self, props, content)
        local arguments = self.__mArguments
        self:__prepareZenityCommand(arguments, props)
        _addOption(arguments, "--text-info")
        _addOption(arguments, _SHELL_SYNTAX_NO_STDERR)

        local cmdStr = _getCommandString(arguments)
        local f = io.popen(cmdStr, constants.FILE_MODE_WRITE_ERASE)
        utils.clearTable(arguments)
        f:write(content)
        utils.readAndCloseFile(f)
    end,


    showEntry = function(self, props)
        local arguments = self.__mArguments
        self:__prepareZenityCommand(arguments, props)
        _addOption(arguments, "--entry")
        _addOptionAndValue(arguments, "--text", props.entryTitle)
        _addOptionAndValue(arguments, "--entry-text", props.entryText)
        return self:_getZenityCommandResult(arguments)
    end,


    showListBox = function(self, props, outIndexes)
        local arguments = self.__mArguments
        self:__prepareZenityCommand(arguments, props)
        _addOption(arguments, "--list")
        _addOptionAndValue(arguments, "--text", props.listBoxTitle)
        _addOption(arguments, props.isHeaderHidden and "--hide-header")

        local isFirstColumnDummy = false
        if props.isMultiSelectable
        then
            _addOption(arguments, "--checklist")
            _addOptionAndValue(arguments, "--separator", _ZENITY_SEP_LISTBOX_INDEX)

            -- 第一列被用作 CheckList 了囧
            _addOptionAndValue(arguments, "--column", constants.STR_EMPTY)
            isFirstColumnDummy = true
        end

        -- 加一列作为返回值
        local hiddenIDColIdx = 1 + types.toNumber(isFirstColumnDummy)
        _addOptionAndValue(arguments, "--column", constants.STR_EMPTY)
        _addOptionAndValue(arguments, "--print-column", hiddenIDColIdx)
        _addOptionAndValue(arguments, "--hide-column", hiddenIDColIdx)

        -- 表头
        local columnCount = props.listBoxColumnCount
        local hasHeader = (not types.isEmptyTable(props.listBoxHeaders))
        for i = 1, columnCount
        do
            local header = hasHeader and props.listBoxHeaders[i] or constants.STR_EMPTY
            _addOptionAndValue(arguments, "--column", header)
        end

        -- 表格内容
        local tableCellCount = #props.listBoxElements
        local rowCount = (columnCount > 0) and math.ceil(tableCellCount / columnCount) or 0
        for i = 1, rowCount
        do
            -- CheckList 列
            if isFirstColumnDummy
            then
                _addValue(arguments, constants.STR_EMPTY)
            end

            -- 返回值列
            _addValue(arguments, i)

            for j = 1, columnCount
            do
                local idx = (i - 1) * columnCount + j
                local element = props.listBoxElements[idx]
                element = element and element or constants.STR_EMPTY
                _addValue(arguments, element)
            end
        end

        -- 返回点击的行索引
        utils.clearTable(outIndexes)
        local resultStr = self:_getZenityCommandResult(arguments)
        if not types.isNilOrEmpty(resultStr) and types.isTable(outIndexes)
        then
            for idx in resultStr:gmatch(_ZENITY_PATTERN_SPLIT_INDEXES)
            do
                table.insert(outIndexes, tonumber(idx))
            end
        end

        return not types.isEmptyTable(outIndexes)
    end,


    showFileSelection = function(self, props, outPaths)
        local arguments = self.__mArguments
        self:__prepareZenityCommand(arguments, props)
        _addOption(arguments, "--file-selection")
        _addOptionAndValue(arguments, "--separator", _ZENITY_SEP_FILE_SELECTION)
        _addOption(arguments, props.isMultiSelectable and "--multiple")
        _addOption(arguments, props.isDirectoryOnly and "--directory")

        utils.clearTable(outPaths)
        local resultStr = self:_getZenityCommandResult(arguments)
        if types.isNilOrEmpty(resultStr)
        then
            return
        end

        local startIdx = 1
        local endIdx = resultStr:len()
        while startIdx <= endIdx
        do
            local sepIdx = resultStr:find(_ZENITY_SEP_FILE_SELECTION, startIdx, true)
            local pathEndIdx = sepIdx and sepIdx - 1 or endIdx
            if startIdx <= pathEndIdx
            then
                table.insert(outPaths, resultStr:sub(startIdx, pathEndIdx))
            end

            startIdx = pathEndIdx + #_ZENITY_SEP_FILE_SELECTION + 1
        end

        return not types.isEmptyTable(outPaths)
    end,


    showProgressBar = function(self, props)
        local arguments = self.__mArguments
        self:__prepareZenityCommand(arguments, props)
        _addOption(arguments, "--progress")
        _addOption(arguments, props.isAutoClose and "--auto-close")
        _addSyntax(arguments, _SHELL_SYNTAX_NO_STDERR)

        local cmdStr = _getCommandString(arguments)
        local handler = io.popen(cmdStr, constants.FILE_MODE_WRITE_ERASE)
        utils.clearTable(arguments)
        return handler
    end,


    advanceProgressBar = function(self, handler, percentage, message)
        if types.isOpenedFile(handler) and percentage > 0
        then
            -- 进度
            handler:write(tostring(math.floor(percentage)))
            handler:write(constants.STR_NEWLINE)

            -- 提示字符
            if types.isString(message)
            then
                handler:write(_ZENITY_PREFFIX_PROGRESS_MESSAGE)
                handler:write(message)
                handler:write(constants.STR_NEWLINE)
            end

            handler:flush()
        end
    end,

    finishProgressBar = function(self, handler)
        utils.readAndCloseFile(handler)
    end,

    showQuestion = function(self, props)
        local arguments = self.__mArguments
        self:__prepareZenityCommand(arguments, props)
        _addOption(arguments, "--question")
        _addOptionAndValue(arguments, "--text", props.questionText)
        _addOptionAndValue(arguments, "--ok-label", props.labelTextOK)
        _addOptionAndValue(arguments, "--cancel-label", props.labelTextCancel)
        return self:_getZenityCommandResult(arguments)
    end,
}

classlite.declareClass(ZenityGUIBuilder)


local _NetworkConnectionBase =
{
    _mIsCompressed      = classlite.declareConstantField(false),
    _mHeaders           = classlite.declareTableField(),
    _mCallbacks         = classlite.declareTableField(),
    _mCallbackArgs      = classlite.declareTableField(),
    _mConnections       = classlite.declareTableField(),
    _mTimeoutSeconds    = classlite.declareConstantField(nil),

    _createConnection = constants.FUNC_EMPTY,
    _readConnection = constants.FUNC_EMPTY,

    setTimeout = function(self, timeout)
        self._mTimeoutSeconds = types.isNumber(timeout) and timeout > 0 and timeout
    end,

    receive = function(self, url)
        if types.isString(url)
        then
            local succeed, conn = self:_createConnection(url)
            local content = succeed and self:_readConnection(conn)
            return content
        end
    end,

    receiveLater = function(self, url, callback, arg)
        if types.isString(url) and types.isFunction(callback)
        then
            local succeed, conn = self:_createConnection(url)
            if succeed
            then
                -- 注意参数有可为空
                local newCount = #self._mConnections + 1
                self._mConnections[newCount] = conn
                self._mCallbacks[newCount] = callback
                self._mCallbackArgs[newCount] = arg
                return true
            end
        end
    end,

    flushReceiveQueue = function(self, url)
        local conns = self._mConnections
        local callbacks = self._mCallbacks
        local callbackArgs = self._mCallbackArgs
        local callbackCount = #callbacks
        for i = 1, callbackCount
        do
            local content = self:_readConnection(conns[i])
            callbacks[i](content, callbackArgs[i])
            conns[i] = nil
            callbacks[i] = nil
            callbackArgs[i] = nil
        end
    end,

    clearHeaders = function(self)
        self._mIsCompressed = false
        utils.clearTable(self._mHeaders)
        return self
    end,

    setCompressed = function(self, val)
        self._mIsCompressed = types.toBoolean(val)
    end,

    addHeader = function(self, val)
        if types.isString(val)
        then
            table.insert(self._mHeaders, val)
        end
    end,
}

classlite.declareClass(_NetworkConnectionBase)


local CURLNetworkConnection =
{
    __mArguments        = classlite.declareTableField(),

    __buildCommandString = function(self, url)
        local arguments = utils.clearTable(self.__mArguments)
        _addCommand(arguments, "curl")
        _addOption(arguments, "--silent")
        _addOption(arguments, self._mIsCompressed and "--compressed")
        _addOptionAndValue(arguments, "--max-time", self._mTimeoutSeconds)
        for _, header in ipairs(self._mHeaders)
        do
            _addOptionAndValue(arguments, "-H", header)
        end
        _addValue(arguments, url)
        return _getCommandString(arguments)
    end,

    _createConnection = function(self, url)
        local cmd = self:__buildCommandString(url)
        local f = io.popen(cmd)
        return types.isOpenedFile(f), f
    end,

    _readConnection = function(self, conn)
        return conn:read(constants.READ_MODE_ALL)
    end,
}

classlite.declareClass(CURLNetworkConnection, _NetworkConnectionBase)


local _UNIQUE_PATH_FMT_FILE_NAME    = "%s%s%03d%s"
local _UNIQUE_PATH_FMT_TIME_PREFIX  = "%y%m%d%H%M"

local UniquePathGenerator =
{
    _mUniquePathID      = classlite.declareConstantField(1),

    getUniquePath = function(self, dir, prefix, suffix, isExistedFunc, funcArg)
        local timeStr = os.date(_UNIQUE_PATH_FMT_TIME_PREFIX)
        prefix = types.isString(prefix) and prefix or constants.STR_EMPTY
        suffix = types.isString(suffix) and suffix or constants.STR_EMPTY
        while true
        do
            local pathID = self._mUniquePathID
            self._mUniquePathID = pathID + 1

            local fileName = string.format(_UNIQUE_PATH_FMT_FILE_NAME, prefix, timeStr, pathID, suffix)
            local fullPath = joinPath(dir, fileName)
            if not isExistedFunc(funcArg, fullPath)
            then
                return fullPath
            end
        end
    end,
}

classlite.declareClass(UniquePathGenerator)



local _MD5_RESULT_CHAR_COUNT    = 32
local _MD5_PATTERN_GRAB_OUTPUT  = "(%x+)"
local _MD5_PATTERN_CHECK_STRING = "^(%x+)$"


local function calcFileMD5(fullPath, byteCount)
    local arguments = utils.clearTable(__gCommandArguments)
    if types.isNumber(byteCount)
    then
        _addCommand(arguments, "head")
        _addOption(arguments, "-c")
        _addValue(arguments, byteCount)
        _addValue(arguments, fullPath)
        _addSyntax(arguments, _SHELL_SYNTAX_PIPE_STDOUT_TO_INPUT)
        _addCommand(arguments, "md5sum")
    else
        _addCommand(arguments, "md5sum")
        _addValue(arguments, fullPath)
    end

    local succeed, output = _getCommandResult(arguments)
    local ret = succeed and output:match(_MD5_PATTERN_GRAB_OUTPUT)
    utils.clearTable(arguments)

    if ret:match(_MD5_PATTERN_CHECK_STRING) and #ret == _MD5_RESULT_CHAR_COUNT
    then
        return ret
    end
end


local function __executeSimpleCommand(...)
    local arguments = utils.clearTable(__gCommandArguments)
    for i = 1, types.getVarArgCount(...)
    do
        local arg = select(i, ...)
        table.insert(arguments, __quoteShellString(arg))
    end
    table.insert(arguments, _SHELL_SYNTAX_NO_STDERR)

    local succeed = _getCommandResult(arguments)
    utils.clearTable(arguments)
    return succeed
end


local function createDir(fullPath)
    return types.isString(fullPath) and __executeSimpleCommand("mkdir", "-p", fullPath)
end


local function deleteTree(fullPath)
    return types.isString(fullPath) and __executeSimpleCommand("rm", "-rf", fullPath)
end


local function moveTree(fromPath, toPath, preserved)
    local arg = preserved and "--backup=numbered" or "-f"
    return types.isString(fromPath) and __executeSimpleCommand("mv", arg, fromPath, toPath)
end


local function readUTF8File(fullPath)
    if types.isString(fullPath)
    then
        local arguments = utils.clearTable(__gCommandArguments)
        _addCommand(arguments, "enca")
        _addOption(arguments, "-L")
        _addValue(arguments, "zh")
        _addOption(arguments, "-x")
        _addValue(arguments, "utf8")
        _addSyntax(arguments, _SHELL_SYNTAX_REDICT_STDIN)
        _addValue(arguments, fullPath)
        _addSyntax(arguments, _SHELL_SYNTAX_NO_STDERR)

        local commandString = _getCommandString(arguments)
        utils.clearTable(arguments)
        return io.popen(commandString)
    end
end


return
{
    _NetworkConnectionBase      = _NetworkConnectionBase,

    TextInfoProperties          = TextInfoProperties,
    EntryProperties             = EntryProperties,
    ListBoxProperties           = ListBoxProperties,
    FileSelectionProperties     = FileSelectionProperties,
    ProgressBarProperties       = ProgressBarProperties,
    QuestionProperties          = QuestionProperties,

    ZenityGUIBuilder            = ZenityGUIBuilder,
    CURLNetworkConnection       = CURLNetworkConnection,
    UniquePathGenerator         = UniquePathGenerator,
    PathElementIterator         = PathElementIterator,

    calcFileMD5                 = calcFileMD5,
    createDir                   = createDir,
    deleteTree                  = deleteTree,
    moveTree                    = moveTree,
    readUTF8File                = readUTF8File,

    normalizePath               = normalizePath,
    joinPath                    = joinPath,
    splitPath                   = splitPath,
    getRelativePath             = getRelativePath,
}
------------------------ src/base/unportable.lua <END> -------------------------

            end
            requestedModule = src_base_unportable_lua()
            __loadedModules[path] = requestedModule
        end
        return requestedModule
    end
    if path == "src/base/utf8"
    then
        local requestedModule = __loadedModules[path]
        if not requestedModule
        then
            local function src_base_utf8_lua()


-------------------------- src/base/utf8.lua <START> ---------------------------
local _algo     = require("src/base/_algo")
local types     = require("src/base/types")
local constants = require("src/base/constants")


local _DECODE_BYTE_RANGE_STARTS         = { 0x00, 0x80, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc }
local _DECODE_BYTE_RANG_ENDS            = { 0x7f, 0xbf, 0xdf, 0xef, 0xf7, 0xfb, 0xfd }
local _DECODE_BYTE_MASKS                = { 0x00, 0x80, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc }
local _DECODE_TRAILING_BYTE_COUNTS      = {  0,    nil,  1,    2,    3,    4,    5   }
local _DECODE_LSHIFT_MULS               = {  1,    64,   32,   16,   8,    4,    2   }
local _DECODE_TRAILING_BYTE_RANGE_INDEX = 2
local _DECODE_BYTE_RANGES_LEN           = #_DECODE_BYTE_RANGE_STARTS

local UTF8_INVALID_CODEPOINT            = -1

local function __compareNumber(rangEnd, val)
    return rangEnd - val
end

local function __binarySearchNums(list, val)
    return _algo.binarySearchArrayIf(list, __compareNumber, val)
end


local function __doIterateUTF8CodePoints(byteString, byteStartIdx)
    local byteLen = byteString:len()
    if byteStartIdx > byteLen
    then
        return nil
    end

    local codePointByteCount = nil
    local codePoint = UTF8_INVALID_CODEPOINT
    local remainingByteCount = 0
    local nextStartByteIdx = byteLen
    for byteIdx = byteStartIdx, byteLen
    do
        nextStartByteIdx = byteIdx + 1

        -- 判断是 UTF8 字节类型
        -- 不是所有字节都是有效的 UTF8 字节，例如 0b11111111
        local b = byteString:byte(byteIdx)
        local found, idx = __binarySearchNums(_DECODE_BYTE_RANG_ENDS, b)
        if not found and idx > _DECODE_BYTE_RANGES_LEN
        then
            break
        end

        -- 出现连续的首字节，或首字节不合法
        local hasFirstByte = (codePoint ~= UTF8_INVALID_CODEPOINT)
        local isFirstByte = (idx ~= _DECODE_TRAILING_BYTE_RANGE_INDEX)
        if hasFirstByte == isFirstByte
        then
            codePoint = UTF8_INVALID_CODEPOINT
            break
        end

        if not hasFirstByte
        then
            remainingByteCount = _DECODE_TRAILING_BYTE_COUNTS[idx] + 1
            codePointByteCount = remainingByteCount
        end

        codePoint = (isFirstByte and 0 or codePoint) * _DECODE_LSHIFT_MULS[idx]
        codePoint = codePoint + (b - _DECODE_BYTE_MASKS[idx])
        remainingByteCount = remainingByteCount - 1

        if remainingByteCount <= 0
        then
            break
        end

    end

    -- 下次迭代的起始字节索引, Unicode 编码, 字符串字节长度
    return nextStartByteIdx, codePoint, codePointByteCount
end

local function iterateUTF8CodePoints(byteString)
    if not types.isString(byteString)
    then
        return constants.FUNC_EMPTY
    end
    return __doIterateUTF8CodePoints, byteString, 1
end



local _ENCODE_CODEPOINT_RANGE_ENDS  =
{
    0x7f,
    0x7ff,
    0xffff,
    0x1fffff,
    0x3ffffff,
    0x7fffffff,
}

local _ENCODE_DIVS                  =
{
    2^0,  nil,
    2^6,  2^0,  nil,
    2^12, 2^6,  2^0,  nil,
    2^18, 2^12, 2^6,  2^0,  nil,
    2^24, 2^18, 2^12, 2^6,  2^0,  nil,
    2^30, 2^24, 2^18, 2^12, 2^6,  2^0,  nil,
    2^36, 2^30, 2^24, 2^18, 2^12, 2^6,  2^0,  nil,
}


local _ENCODE_MODS                  =
{
    2^7, nil,
    2^5, 2^6, nil,
    2^4, 2^6, 2^6, nil,
    2^3, 2^6, 2^6, 2^6, nil,
    2^2, 2^6, 2^6, 2^6, 2^6, nil,
    2^1, 2^6, 2^6, 2^6, 2^6, 2^6, nil,
    2^0, 2^6, 2^6, 2^6, 2^6, 2^6, 2^6, nil,
}

local _ENCODE_MASKS                 =
{
    0x00, nil,
    0xc0, 0x80, nil,
    0xe0, 0x80, 0x80, nil,
    0xf0, 0x80, 0x80, 0x80, nil,
    0xf8, 0x80, 0x80, 0x80, 0x80, nil,
    0xfc, 0x80, 0x80, 0x80, 0x80, 0x80, nil,
    0xfe, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, nil,
}

local _ENCODE_ITERATE_INDEXES       = { 1, 3, 6, 10, 15, 21, 28 }

local _CODEPOINT_MIN                = 0
local _CODEPOINT_MAX                = 0x7fffffff


local function __doIterateUTF8EncodedBytes(codePoint, iterIdx)
    local div = _ENCODE_DIVS[iterIdx]
    local mask = _ENCODE_MASKS[iterIdx]
    local mod = _ENCODE_MODS[iterIdx]
    if div and mask and mod
    then
        local ret = math.floor(codePoint / div % mod) + mask
        return iterIdx + 1, ret
    else
        return nil
    end
end


local function iterateUTF8EncodedBytes(codePoint)
    if codePoint > _CODEPOINT_MAX or codePoint < _CODEPOINT_MIN
    then
        return constants.FUNC_EMPTY
    end

    local _, idx = __binarySearchNums(_ENCODE_CODEPOINT_RANGE_ENDS, codePoint)
    local iterIdx = _ENCODE_ITERATE_INDEXES[idx]
    return __doIterateUTF8EncodedBytes, codePoint, iterIdx
end


return
{
    UTF8_INVALID_CODEPOINT  = UTF8_INVALID_CODEPOINT,

    iterateUTF8CodePoints   = iterateUTF8CodePoints,
    iterateUTF8EncodedBytes = iterateUTF8EncodedBytes,
}
--------------------------- src/base/utf8.lua <END> ----------------------------

            end
            requestedModule = src_base_utf8_lua()
            __loadedModules[path] = requestedModule
        end
        return requestedModule
    end
    if path == "src/base/utils"
    then
        local requestedModule = __loadedModules[path]
        if not requestedModule
        then
            local function src_base_utils_lua()


-------------------------- src/base/utils.lua <START> --------------------------
local _algo     = require("src/base/_algo")
local _conv     = require("src/base/_conv")
local types     = require("src/base/types")
local constants = require("src/base/constants")


local function invokeSafely(func, ...)
    if types.isFunction(func)
    then
        -- 即使可能是最后一句，但明确 return 才是尾调用
        return func(...)
    end
end


local function __createSafeInvokeWrapper(funcName)
    local ret = function(obj)
        if types.isTable(obj)
        then
            invokeSafely(obj[funcName], obj)
        end
    end

    return ret
end


local function writeAndCloseFile(f, content)
    if types.isOpenedFile(f)
    then
        local succeed = f:write(content)
        f:close()
        return succeed
    end
end


local function readAndCloseFile(f)
    if types.isOpenedFile(f)
    then
        local readRet = f:read(constants.READ_MODE_ALL)
        return readRet, f:close()
    end
end



local __exports =
{
    invokeSafely        = invokeSafely,
    closeSafely         = __createSafeInvokeWrapper("close"),
    disposeSafely       = __createSafeInvokeWrapper("dispose"),

    writeAndCloseFile   = writeAndCloseFile,
    readAndCloseFile    = readAndCloseFile,
}

_algo.mergeTable(__exports, _algo)
_algo.mergeTable(__exports, _conv)
return __exports
--------------------------- src/base/utils.lua <END> ---------------------------

            end
            requestedModule = src_base_utils_lua()
            __loadedModules[path] = requestedModule
        end
        return requestedModule
    end
    if path == "src/core/_ass"
    then
        local requestedModule = __loadedModules[path]
        if not requestedModule
        then
            local function src_core__ass_lua()


-------------------------- src/core/_ass.lua <START> ---------------------------
local utils     = require("src/base/utils")
local types     = require("src/base/types")
local constants = require("src/base/constants")
local classlite = require("src/base/classlite")


local _ASS_CONST_SEP_FIELD              = ", "
local _ASS_CONST_SEP_KEY_VALUE          = ": "
local _ASS_CONST_SEP_LINE               = "\n"
local _ASS_CONST_HEADER_NAME_START      = "["
local _ASS_CONST_HEADER_NAME_END        = "]"
local _ASS_CONST_STYLE_START            = "{"
local _ASS_CONST_STYLE_END              = "}"

local _ASS_CONST_BOOL_TRUE              = "-1"
local _ASS_CONST_BOOL_FALSE             = "0"

local _ASS_CONST_FMT_INT                = "%d"
local _ASS_CONST_FMT_COLOR_ABGR         = "&H%02X%02X%02X%02X"
local _ASS_CONST_FMT_DIALOGUE_TIME      = "%d:%02d:%05.02f"

local _ASS_CONST_STYLENAME_DANMAKU      = "_mdl_default"
local _ASS_CONST_STYLENAME_SUBTITLE     = "_mdl_subtitle"

local _ASS_CONST_MOD_COLOR_RGB          = 0xFFFFFF + 1

local _ASS_HEADERNAME_SCRIPT_INFO       = "Script Info"
local _ASS_HEADERNAME_STYLES            = "V4+ Styles"
local _ASS_HEADERNAME_EVENTS_           = "Events"

local _ASS_KEYNAME_SCRIPTINFO_WIDTH     = "PlayResX"
local _ASS_KEYNAME_SCRIPTINFO_HEIGHT    = "PlayResY"
local _ASS_KEYNAME_STYLE_FORMAT         = "Format"
local _ASS_KEYNAME_STYLE_STYLE          = "Style"
local _ASS_KEYNAME_EVENTS_FORMAT        = "Format"
local _ASS_KEYNAME_EVENTS_DIALOGUE      = "Dialogue"

local _ASS_VALNAME_STYLE_STYLENAME      = "Name"
local _ASS_VALNAME_STYLE_FONTNAME       = "Fontname"
local _ASS_VALNAME_STYLE_FONTSIZE       = "Fontsize"
local _ASS_VALNAME_STYLE_FONTCOLOR      = "PrimaryColour"

local _ASS_ARRAY_EVENTS_KEYNAMES        = { "Layer", "Start", "End", "Style", "Text" }

local __gStyleData      = {}
local __gWriteFields    = {}


local function _convertARGBHexToABGRColorString(num)
    local a, r, g, b = utils.splitARGBHex(num)
    return string.format(_ASS_CONST_FMT_COLOR_ABGR, a, b, g, r)
end

local function _convertNumberToIntString(num)
    return string.format(_ASS_CONST_FMT_INT, math.floor(num))
end

local function __createStringValidator(str)
    local ret = function(val, default)
        return types.isString(val) and #val > 0 and val or default
    end
    return ret
end

local function __createIntValidator(minVal, maxVal, hook)
    local ret = function(val, default)
        val = types.isNumber(val) and val or default
        val = minVal and math.max(val, minVal) or val
        val = maxVal and math.min(val, maxVal) or val
        return hook and hook(val) or _convertNumberToIntString(val)
    end
    return ret
end

local function __createColorValidator()
    return __createIntValidator(nil, nil, _convertARGBHexToABGRColorString)
end

local function __createBoolValidator()
    local function __toBoolString(val)
        if types.isBoolean(val)
        then
            return val and _ASS_CONST_BOOL_TRUE or _ASS_CONST_BOOL_FALSE
        end
    end

    local ret = function(val, default)
        return __toBoolString(val)
            or __toBoolString(default)
            or _ASS_CONST_BOOL_FALSE
    end
    return ret
end


local _ASS_CONST_STYLE_DEF_IDX_VALIDATOR    = 1
local _ASS_CONST_STYLE_DEF_IDX_DANMAKU      = 2
local _ASS_CONST_STYLE_DEF_IDX_SUBTITLE     = 3


local _ASS_PAIRS_SCRIPT_INFO_CONTENT =
{
    "Script Updated By",    "MPVDanmakuLoader",
    "ScriptType",           "v4.00+",
    "Collisions",           "Normal",
    "WrapStyle",            "2",
}


-- 弹幕样式抄自 https://github.com/cnbeining/Biligrab/blob/master/danmaku2ass2.py
-- 字幕样式抄自 http://www.zimuku.net/detail/45087.html
local _ASS_PAIRS_STYLE_DEFINITIONS =
{
    _ASS_VALNAME_STYLE_STYLENAME,   { __createStringValidator(),        _ASS_CONST_STYLENAME_DANMAKU,   _ASS_CONST_STYLENAME_SUBTITLE, },
    _ASS_VALNAME_STYLE_FONTNAME,    { __createStringValidator(),        "sans-serif",                   "mono",                        },
    _ASS_VALNAME_STYLE_FONTSIZE,    { __createIntValidator(1),          34,                             34,                            },
    _ASS_VALNAME_STYLE_FONTCOLOR,   { __createColorValidator(),         0x33FFFFFF,                     0x00FFFFFF,                    },
    "SecondaryColour",              { __createColorValidator(),         0x33FFFFFF,                     0xFF000000,                    },
    "OutlineColour",                { __createColorValidator(),         0x33000000,                     0x0000336C,                    },
    "BackColour",                   { __createColorValidator(),         0x33000000,                     0x00000000,                    },
    "Bold",                         { __createBoolValidator(),          false,                          false,                         },
    "Italic",                       { __createBoolValidator(),          false,                          false,                         },
    "Underline",                    { __createBoolValidator(),          false,                          false,                         },
    "StrikeOut",                    { __createBoolValidator(),          false,                          false,                         },
    "ScaleX",                       { __createIntValidator(0, 100),     100,                            100                            },
    "ScaleY",                       { __createIntValidator(0, 100),     100,                            100                            },
    "Spacing",                      { __createIntValidator(0),          0,                              0,                             },
    "Angle",                        { __createIntValidator(0, 360),     0,                              0,                             },
    "BorderStyle",                  { __createIntValidator(1, 3),       1,                              1,                             },
    "Outline",                      { __createIntValidator(0, 4),       1,                              2,                             },
    "Shadow",                       { __createIntValidator(0, 4),       0,                              1,                             },
    "Alignment",                    { __createIntValidator(1, 9),       7,                              2,                             },
    "MarginL",                      { __createIntValidator(0),          0,                              5,                             },
    "MarginR",                      { __createIntValidator(0),          0,                              5,                             },
    "MarginV",                      { __createIntValidator(0),          0,                              8,                             },
    "Encoding",                     { __createIntValidator(0),          0,                              0,                             },
}



local function _writeKeyValue(f, k, v)
    f:write(k, _ASS_CONST_SEP_KEY_VALUE, v, _ASS_CONST_SEP_LINE)
end


local function _writeHeader(f, name)
    f:write(_ASS_CONST_HEADER_NAME_START, name, _ASS_CONST_HEADER_NAME_END)
    f:write(_ASS_CONST_SEP_LINE)
end


local function writeScriptInfo(f, width, height)
    _writeHeader(f, _ASS_HEADERNAME_SCRIPT_INFO)

    for _, k, v in utils.iteratePairsArray(_ASS_PAIRS_SCRIPT_INFO_CONTENT)
    do
        _writeKeyValue(f, k, v)
    end

    _writeKeyValue(f, _ASS_KEYNAME_SCRIPTINFO_WIDTH, _convertNumberToIntString(width))
    _writeKeyValue(f, _ASS_KEYNAME_SCRIPTINFO_HEIGHT, _convertNumberToIntString(height))

    f:write(_ASS_CONST_SEP_LINE)
end


local function _writeFields(f, fields)
    for i, field in ipairs(fields)
    do
        -- 仅在元素之前加分割符
        if i ~= 1
        then
            f:write(_ASS_CONST_SEP_FIELD)
        end

        f:write(field)
    end
    f:write(_ASS_CONST_SEP_LINE)
end


local function writeStyleHeader (f)
    local styleNames = utils.clearTable(__gWriteFields)
    for _, name in utils.iteratePairsArray(_ASS_PAIRS_STYLE_DEFINITIONS)
    do
        table.insert(styleNames, name)
    end
    _writeHeader(f, _ASS_HEADERNAME_STYLES)
    f:write(_ASS_KEYNAME_STYLE_FORMAT)
    f:write(_ASS_CONST_SEP_KEY_VALUE)
    _writeFields(f, styleNames)
    utils.clearTable(styleNames)
end


local function writeEventsHeader(f)
    f:write(_ASS_CONST_SEP_LINE)
    _writeHeader(f, _ASS_HEADERNAME_EVENTS_)
    f:write(_ASS_KEYNAME_EVENTS_FORMAT, _ASS_CONST_SEP_KEY_VALUE)
    _writeFields(f, _ASS_ARRAY_EVENTS_KEYNAMES)
end


local function __createWriteStyleFunction(styleIdx)
    local ret = function(f, modifyHook, fontName, fontSize, fontColor)
        local styleData = utils.clearTable(__gStyleData)
        styleData[_ASS_VALNAME_STYLE_FONTNAME] = fontName
        styleData[_ASS_VALNAME_STYLE_FONTCOLOR] = fontColor
        styleData[_ASS_VALNAME_STYLE_FONTSIZE] = fontSize
        pcall(modifyHook, styleData)

        local styleValues = utils.clearTable(__gWriteFields)
        for _, name, defData in utils.iteratePairsArray(_ASS_PAIRS_STYLE_DEFINITIONS)
        do
            local validator = defData[_ASS_CONST_STYLE_DEF_IDX_VALIDATOR]
            local defaultValue = defData[styleIdx]
            local value = validator(styleData[name], defaultValue)
            table.insert(styleValues, value)
        end

        f:write(_ASS_KEYNAME_STYLE_STYLE)
        f:write(_ASS_CONST_SEP_KEY_VALUE)
        _writeFields(f, styleValues)
        utils.clearTable(styleData)
        utils.clearTable(styleValues)
    end
    return ret
end


local function __convertTimeToTimeString(builder, time)
    if types.isNumber(time)
    then
        local h, m, s = utils.convertTimeToHMS(time)
        return string.format(_ASS_CONST_FMT_DIALOGUE_TIME, h, m, s)
    end
end

local function __toASSEscapedString(builder, val)
    return types.isString(val) and utils.escapeASSString(val)
end

local function __toIntNumberString(builder, val)
    return types.isNumber(val) and _convertNumberToIntString(val)
end

local function __toNonDefaultFontSize(builder, fontSize)
    return types.isNumber(fontSize)
        and fontSize ~= builder._mDefaultFontSize
        and _convertNumberToIntString(fontSize)
end

local function __toNonDefaultFontColor(builder, fontColor)
    local function __getRGBHex(num)
        return types.isNumber(num) and math.floor(num % _ASS_CONST_MOD_COLOR_RGB)
    end

    return types.isNumber(fontColor)
        and __getRGBHex(fontColor) ~= __getRGBHex(builder._mDefaultFontColor)
        and _convertARGBHexToABGRColorString(fontColor)
end


local function __createBuilderMethod(...)
    local params = { ... }
    local ret = function(self, ...)
        local argIdx = 1
        local contentLastIdxBak = #self._mContent
        for _, param in ipairs(params)
        do
            local val = nil
            if types.isString(param)
            then
                -- 字符常量
                val = param
            elseif types.isFunction(param)
            then
                -- 函数返回值是字符串
                local arg = select(argIdx, ...)
                val = arg and param(self, arg)
                argIdx = argIdx + 1
            end

            if not val
            then
                -- 只要有一次返回空值，就取消本次写操作
                utils.clearArray(self._mContent, contentLastIdxBak + 1)
                break
            else
                table.insert(self._mContent, val)
            end
        end

        return self
    end

    return ret
end


local DialogueBuilder =
{
    _mContent               = classlite.declareTableField(),
    _mStyleName             = classlite.declareConstantField(nil),
    _mDefaultFontColor      = classlite.declareConstantField(nil),
    _mDefaultFontSize       = classlite.declareConstantField(nil),

    __doInitStyle = function(self, idx)
        local function __getStyleDefinitionValue(name, styleIdx)
            local found, idx = utils.linearSearchArray(_ASS_PAIRS_STYLE_DEFINITIONS, name)
            return found and _ASS_PAIRS_STYLE_DEFINITIONS[idx + 1][styleIdx]
        end

        self._mStyleName        = __getStyleDefinitionValue(_ASS_VALNAME_STYLE_STYLENAME, idx)
        self._mDefaultFontColor = __getStyleDefinitionValue(_ASS_VALNAME_STYLE_FONTCOLOR, idx)
        self._mDefaultFontSize  = __getStyleDefinitionValue(_ASS_VALNAME_STYLE_FONTSIZE, idx)
    end,

    initDanmakuStyle = function(self)
        self:__doInitStyle(_ASS_CONST_STYLE_DEF_IDX_DANMAKU)
    end,

    initSubtitleStyle = function(self)
        self:__doInitStyle(_ASS_CONST_STYLE_DEF_IDX_SUBTITLE)
    end,

    clear = function(self)
        utils.clearTable(self._mContent)
    end,

    flushContent = function(self, f)
        local content = self._mContent
        local contentLen = #content
        for i = 1, contentLen
        do
            f:write(content[i])
            content[i] = nil
        end
    end,

    startDialogue = function(self, layer, startTime, endTime)
        return self:__doStartDialogue(layer, startTime, endTime, self._mStyleName)
    end,


    __doStartDialogue       = __createBuilderMethod(_ASS_KEYNAME_EVENTS_DIALOGUE,
                                                    _ASS_CONST_SEP_KEY_VALUE,
                                                    __toIntNumberString,        -- layer
                                                    _ASS_CONST_SEP_FIELD,
                                                    __convertTimeToTimeString,  -- startTime
                                                    _ASS_CONST_SEP_FIELD,
                                                    __convertTimeToTimeString,  -- endTime
                                                    _ASS_CONST_SEP_FIELD,
                                                    __toASSEscapedString,       -- styleName
                                                    _ASS_CONST_SEP_FIELD),

    endDialogue             = __createBuilderMethod(_ASS_CONST_SEP_LINE),

    startStyle              = __createBuilderMethod(_ASS_CONST_STYLE_START),

    endStyle                = __createBuilderMethod(_ASS_CONST_STYLE_END),

    addText                 = __createBuilderMethod(__toASSEscapedString),

    addTopCenterAlign       = __createBuilderMethod("\\an8"),

    addBottomCenterAlign    = __createBuilderMethod("\\an2"),

    addMove                 = __createBuilderMethod("\\move(",
                                                    __toIntNumberString,        -- startX
                                                    _ASS_CONST_SEP_FIELD,
                                                    __toIntNumberString,        -- startY
                                                    _ASS_CONST_SEP_FIELD,
                                                    __toIntNumberString,        -- endX
                                                    _ASS_CONST_SEP_FIELD,
                                                    __toIntNumberString,
                                                    ")"),

    addPos                  = __createBuilderMethod("\\pos(",
                                                    __toIntNumberString,        -- x
                                                    _ASS_CONST_SEP_FIELD,
                                                    __toIntNumberString,        -- y
                                                    ")"),

    addFontColor            = __createBuilderMethod("\\c",
                                                    __toNonDefaultFontColor,    -- rgb
                                                    "&"),

    addFontSize             = __createBuilderMethod("\\fs",
                                                    __toNonDefaultFontSize),    -- fontSize
}

classlite.declareClass(DialogueBuilder)


return
{
    writeScriptInfo         = writeScriptInfo,
    writeStyleHeader        = writeStyleHeader,
    writeDanmakuStyle       = __createWriteStyleFunction(_ASS_CONST_STYLE_DEF_IDX_DANMAKU),
    writeSubtitleStyle      = __createWriteStyleFunction(_ASS_CONST_STYLE_DEF_IDX_SUBTITLE),
    writeEventsHeader       = writeEventsHeader,
    DialogueBuilder         = DialogueBuilder,
}

--------------------------- src/core/_ass.lua <END> ----------------------------

            end
            requestedModule = src_core__ass_lua()
            __loadedModules[path] = requestedModule
        end
        return requestedModule
    end
    if path == "src/core/_coreconstants"
    then
        local requestedModule = __loadedModules[path]
        if not requestedModule
        then
            local function src_core__coreconstants_lua()


--------------------- src/core/_coreconstants.lua <START> ----------------------
return
{
    LAYER_MOVING_L2R            = 1,
    LAYER_MOVING_R2L            = 2,
    LAYER_STATIC_TOP            = 3,
    LAYER_STATIC_BOTTOM         = 4,
    LAYER_ADVANCED              = 5,
    LAYER_SUBTITLE              = 6,
    LAYER_SKIPPED               = 7,

    _DANMAKU_IDX_START_TIME     = 1,    -- 弹幕起始时间，单位 ms
    _DANMAKU_IDX_LIFE_TIME      = 2,    -- 弹幕存活时间，单位 ms
    _DANMAKU_IDX_FONT_COLOR     = 3,    -- 字体颜色值，格式 RRGGBB
    _DANMAKU_IDX_FONT_SIZE      = 4,    -- 字体大小，单位 pt
    _DANMAKU_IDX_SOURCE_ID      = 5,    -- 弹幕源
    _DANMAKU_IDX_DANMAKU_ID     = 6,    -- 在相同弹幕源前提下的唯一标识
    _DANMAKU_IDX_DANMAKU_TEXT   = 7,    -- 弹幕内容，以 utf8 编码
    _DANMAKU_IDX_MAX            = 7,
}
---------------------- src/core/_coreconstants.lua <END> -----------------------

            end
            requestedModule = src_core__coreconstants_lua()
            __loadedModules[path] = requestedModule
        end
        return requestedModule
    end
    if path == "src/core/_poscalc"
    then
        local requestedModule = __loadedModules[path]
        if not requestedModule
        then
            local function src_core__poscalc_lua()


------------------------ src/core/_poscalc.lua <START> -------------------------
local types     = require("src/base/types")
local utils     = require("src/base/utils")
local constants = require("src/base/constants")
local classlite = require("src/base/classlite")


local __DanmakuArea =
{
    width   = classlite.declareConstantField(0),    -- 宽度
    height  = classlite.declareConstantField(0),    -- 高度
    start   = classlite.declareConstantField(0),    -- 刚好出现屏幕边缘的时刻
    speed   = classlite.declareConstantField(1),    -- 水平移动速度
    _next   = classlite.declareConstantField(nil),  -- 链表指针


    split = function(self, h1, h2, cloneArea)
        local newArea = self:clone(cloneArea)
        self.height = h1
        self._next = newArea
        newArea.height = h2
        return self, newArea
    end,


    getCollidingDuration = function(a1, a2, screenWidth)
        if a1.speed == math.huge or a2.speed == math.huge
        then
            return 0
        end

        -- 保证最先出现的是 a1
        if a1.start > a2.start
        then
            local tmp = a1
            a1 = a2
            a2 = tmp
        end

        -- a2 要追上 a1 要走的相对距离
        local startTimeDelta = math.max(a2.start - a1.start, 0)
        local movedDistance1 = a1.speed * startTimeDelta
        local chasingDistance = math.max(movedDistance1 - a1.width, 0)

        -- 计算 a1 / a2 存活时间
        local lifeTime1 = (a1.width + screenWidth) / a1.speed
        local lifeTime2 = (a2.width + screenWidth) / a2.speed

        -- 以 a2 刚好出现作为基准点，记录几个关键时刻
        local dieOutTime1 = math.max(lifeTime1 - startTimeDelta, 0)
        local dieOutTime2 = lifeTime2

        -- 避免除零错误，提前判这种情况
        -- 根据初始状态是否相交，就可以知道碰撞时间了
        if a1.speed == a2.speed
        then
            if chasingDistance == 0
            then
                return math.min(dieOutTime1, dieOutTime2)
            else
                return 0
            end
        end

        -- 明显追不上
        if a2.speed <= a1.speed and chasingDistance > 0
        then
            return 0
        end

        -- 计算从 刚好接触 到 刚好分离 需要走的相对距离，注意判断 a2 最终是否会赶上 a1
        local disjointDistance = 0
        if a2.speed > a1.speed
        then
            disjointDistance = movedDistance1 < a1.width
                               and a1.width - movedDistance1 + a2.width
                               or a1.width + a2.width
        else
            disjointDistance = movedDistance1 < a1.width
                               and a1.width - movedDistance1
                               or 0
        end

        -- 计算 刚好追上 / 刚好相离 所花费的时间
        local speedDelta = math.abs(a2.speed - a1.speed)
        local chasedElapsed = math.max(chasingDistance / speedDelta, 0)
        local disjointElapsed = math.max(disjointDistance / speedDelta, 0)

        -- 如果某一方提前消失，从该时刻开始就不算碰撞
        local remainingTime = math.min(dieOutTime1, dieOutTime2)
        local remainingTimeAfterChased = math.max(remainingTime - chasedElapsed, 0)
        local collidingDuration = math.min(remainingTimeAfterChased, disjointElapsed)

        return collidingDuration
    end,
}

classlite.declareClass(__DanmakuArea);


local function __getIntersectedHeight(top1, bottom1, top2, bottom2)
    local h1 = 0
    local h2 = 0
    local h3 = 0

    if top1 >= bottom2
    then
        -- 完全在上方
        h1 = bottom2 - top2
    elseif top2 >= bottom1
    then
        -- 完全在下方
        h3 = bottom2 - top2
    else
        h1 = math.max(math.min(top1, bottom2) - top2, 0)
        h2 = math.min(bottom1, bottom2) - math.max(top1, top2)
        h3 = math.max(bottom2 - math.max(bottom1, top2), 0)
    end

    -- 结果只针对第二个区域而言
    -- 上溢出高度, 相交高度, 下溢出高度
    return h1, h2, h3
end



local __BasePosCalculator =
{
    _mScreenWidth       = classlite.declareConstantField(1),
    _mScreenHeight      = classlite.declareConstantField(1),
    _mDanmakuAreas      = classlite.declareConstantField(nil),
    __mTmpDanmakuArea   = classlite.declareClassField(__DanmakuArea),
    __mFreeDanmakuAreas = classlite.declareTableField(),


    _doGetCollisionScore = constants.FUNC_EMPTY,
    _doInitDanmakuArea = constants.FUNC_EMPTY,
    _doUpdateDanmakuArea = constants.FUNC_EMPTY,


    init = function(self, width, height)
        self._mScreenWidth = math.floor(width)
        self._mScreenHeight = math.floor(height)
        self:__recycleDanmakuAreas()
        self._mDanmakuAreas = self:_obtainDanmakuArea()
        self:_doInitDanmakuArea(width, height, 0, 0, self._mDanmakuAreas)
    end,

    __recycleDanmakuAreas = function(self)
        local area = self._mDanmakuAreas
        local areaPool = self.__mFreeDanmakuAreas
        while area
        do
            local nextArea = area._next
            table.insert(areaPool, area)
            area = nextArea
        end
        self._mDanmakuAreas = nil
    end,

    _obtainDanmakuArea = function(self)
        return utils.popArrayElement(self.__mFreeDanmakuAreas) or __DanmakuArea:new()
    end,

    dispose = function(self)
        self:__recycleDanmakuAreas()
        utils.forEachArrayElement(self.__mFreeDanmakuAreas, utils.disposeSafely)
    end,


    __getCollisionScoreSum = function(self, iterTop, iterArea, newTop, area2)
        local scoreSum = 0
        local iterBottom = iterTop + iterArea.height
        local newBottom = math.min(newTop + area2.height, self._mScreenHeight)
        while iterArea
        do
            local h1, h2, h3 = __getIntersectedHeight(iterTop, iterBottom, newTop, newBottom)
            local score = h2 > 0 and self:_doGetCollisionScore(iterArea, area2) * h2 or 0
            scoreSum = scoreSum + score

            -- 继续向下遍历也不会相交
            if h1 > 0 and h2 == 0
            then
                break
            end

            iterArea = iterArea._next
            iterTop = iterBottom
            iterBottom = iterTop + (iterArea and iterArea.height or 0)
        end

        return scoreSum
    end,


    __addDanmakuArea = function(self, iterArea, iterTop, area2, newTop)
        local iterBottom = iterTop
        local newBottom = newTop + area2.height
        while iterArea
        do
            iterTop = iterBottom
            iterBottom = iterTop + iterArea.height

            local h1, h2, h3 = __getIntersectedHeight(iterTop, iterBottom, newTop, newBottom)
            if h1 > 0 and h2 == 0
            then
                break
            end

            -- 很多时候只是部分相交，所以需要切割
            if h2 > 0
            then
                local newH1, _, newH3 = __getIntersectedHeight(newTop, newBottom, iterTop, iterBottom)

                -- 切割不相交的上半部分
                if newH1 > 0
                then
                    local newArea = self:_obtainDanmakuArea()
                    local upperArea, lowerArea = iterArea:split(newH1, h2, newArea)
                    iterArea = lowerArea
                end

                -- 切割不相交的下半部分
                if newH3 > 0
                then
                    local newArea = self:_obtainDanmakuArea()
                    local upperArea, lowerArea = iterArea:split(h2, newH3, newArea)
                    iterArea = upperArea
                end

                -- 可能做了切割，必须更新高度信息，不然下一轮遍历会出错
                iterTop = iterTop + newH1
                iterBottom = iterTop + h2

                -- 切割之后两者区域上下边界都相同
                iterArea.height = h2
                self:_doUpdateDanmakuArea(iterArea, area2)
            end

            iterArea = iterArea._next
        end
    end,


    calculate = function(self, w, h, start, lifeTime)
        -- 区域位置全部用整数表示
        h = math.ceil(h)

        local screenTop = 0
        local screenBottom = self._mScreenHeight
        local danmakuTop = screenTop
        local danmakuBottom = danmakuTop + h

        local minScore = math.huge
        local retY = screenTop
        local insertArea = self._mDanmakuAreas
        local insertAreaTop = screenTop

        local iterArea = self._mDanmakuAreas
        local area2 = self:_doInitDanmakuArea(w, h, start, lifeTime, self.__mTmpDanmakuArea)
        local iterAreaBottom = 0
        while iterArea
        do
            -- 移动区域不记录上下边界，因为总是紧接的
            local iterAreaTop = iterAreaBottom
            iterAreaBottom = iterAreaTop + iterArea.height

            if iterAreaBottom >= danmakuTop
            then
                local score = self:__getCollisionScoreSum(iterAreaTop, iterArea, danmakuTop, area2)
                if score == 0
                then
                    -- 找到完全合适的位置
                    retY = danmakuTop
                    break
                else
                    if minScore > score
                    then
                        minScore = score
                        retY = danmakuTop
                        insertArea = iterArea
                        insertAreaTop = iterAreaTop
                    end

                    local downHeight = iterArea.height
                    danmakuTop = danmakuTop + downHeight
                    danmakuBottom = danmakuBottom + downHeight

                    -- 不允许超出屏幕底边界
                    if danmakuBottom > self._mScreenHeight
                    then
                        break
                    end
                end
            end

            iterArea = iterArea._next
        end

        self:__addDanmakuArea(insertArea, insertAreaTop, area2, retY)
        return retY
    end,
}

classlite.declareClass(__BasePosCalculator);



local MovingPosCalculator =
{
    _doGetCollisionScore = function(self, area1, area2)
        return area1:getCollidingDuration(area2, self._mScreenWidth)
    end,


    _doInitDanmakuArea = function(self, w, h, start, lifeTime, outArea)
        local speed = 0
        if lifeTime == 0
        then
            -- 防止出现除零错误
            w = 1
            speed = math.huge
        else
            speed = (w + self._mScreenWidth) / lifeTime
        end

        outArea.width = w
        outArea.height = h
        outArea.start = start
        outArea.speed = speed
        return outArea
    end,


    _doUpdateDanmakuArea = function(self, area1, area2)
        area1.start = area2.start
        area1.speed = area2.speed
        area1.width = area2.width
    end,
}

classlite.declareClass(MovingPosCalculator, __BasePosCalculator)



local StaticPosCalculator =
{
    _doInitDanmakuArea = function(self, w, h, start, lifeTime, outArea)
        -- 这里把 speed 这个字段 hack 成存活时间了
        outArea.start = start
        outArea.width = 1
        outArea.height = h
        outArea.speed = lifeTime
        return outArea
    end,


    _doGetCollisionScore = function(self, area1, area2)
        -- 保证 area1 比 area2 先出现
        if area1.start > area2.start
        then
            local tmp = area1
            area1 = area2
            area2 = tmp
        end

        -- 计算同时出现的时间
        return math.max(area1.start + area1.speed - area2.start, 0)
    end,


    _doUpdateDanmakuArea = function(self, area1, area2)
        local endTime1 = area1.start + area1.speed
        local endTime2 = area2.start + area2.speed

        area1.start = math.max(area1.start, area2.start)
        area1.speed = math.max(endTime1, endTime2) - area1.start
        area1.width = area2.width
    end,
}

classlite.declareClass(StaticPosCalculator, __BasePosCalculator)


return
{
    __DanmakuArea           = __DanmakuArea,
    __getIntersectedHeight  = __getIntersectedHeight,

    MovingPosCalculator     = MovingPosCalculator,
    StaticPosCalculator     = StaticPosCalculator,
}
------------------------- src/core/_poscalc.lua <END> --------------------------

            end
            requestedModule = src_core__poscalc_lua()
            __loadedModules[path] = requestedModule
        end
        return requestedModule
    end
    if path == "src/core/_writer"
    then
        local requestedModule = __loadedModules[path]
        if not requestedModule
        then
            local function src_core__writer_lua()


------------------------- src/core/_writer.lua <START> -------------------------
local _ass              = require("src/core/_ass")
local _poscalc          = require("src/core/_poscalc")
local _coreconstants    = require("src/core/_coreconstants")
local utf8              = require("src/base/utf8")
local types             = require("src/base/types")
local utils             = require("src/base/utils")
local constants         = require("src/base/constants")
local classlite         = require("src/base/classlite")
local danmaku           = require("src/core/danmaku")


local function _measureDanmakuText(text, fontSize)
    local lineCount = 1
    local lineCharCount = 0
    local maxLineCharCount = 0
    for _, codePoint in utf8.iterateUTF8CodePoints(text)
    do
        if codePoint == constants.CODEPOINT_NEWLINE
        then
            lineCount = lineCount + 1
            maxLineCharCount = math.max(maxLineCharCount, lineCharCount)
            lineCharCount = 0
        end

        lineCharCount = lineCharCount + 1
    end

    -- 可能没有回车符
    maxLineCharCount = math.max(maxLineCharCount, lineCharCount)

    -- 字体高度系数一般是 1.0 左右
    -- 字体宽度系数一般是 1.0 ~ 0.6 左右
    -- 就以最坏的情况来算吧
    local width = maxLineCharCount * fontSize
    local height = lineCount * fontSize
    return width, height
end


local function _writeMovingL2RPos(cfg, b, screenW, screenH, w, y)
    b:addMove(0, y, screenW + w, y)
end

local function _writeMovingR2LPos(cfg, b, screenW, screenH, w, y)
    b:addMove(screenW, y, -w, y)
end

local function _writeStaticTopPos(cfg, b, screenW, screenH, w, y)
    b:addTopCenterAlign()
    b:addPos(screenW / 2, y)
end


local function __doWriteStaticBottomPos(cfg, b, screenW, screenH, w, y, reservedH)
    local stageH = screenH - reservedH
    y = stageH - y
    y = y - reservedH
    b:addPos(screenW / 2, y)
end

local function _writeStaticBottomPos(cfg, b, screenW, screenH, w, y)
    b:addBottomCenterAlign()
    __doWriteStaticBottomPos(cfg, b, screenW, screenH, w, y, cfg.danmakuReservedBottomHeight)
end

local function _writeBottomSubtitlePos(cfg, b, screenW, screenH, w, y)
    -- 字幕对齐方式由默认样式指定
    __doWriteStaticBottomPos(cfg, b, screenW, screenH, w, y, cfg.subtitleReservedBottomHeight)
end


local DanmakuWriter =
{
    __mDanmakuData      = classlite.declareClassField(danmaku.DanmakuData),
    _mCalculators       = classlite.declareTableField(),
    _mWritePosFunctions = classlite.declareTableField(),
    _mDialogueBuilder   = classlite.declareClassField(_ass.DialogueBuilder),


    new = function(self)
        local calcs = self._mCalculators
        calcs[_coreconstants.LAYER_MOVING_L2R]      = _poscalc.MovingPosCalculator:new()
        calcs[_coreconstants.LAYER_MOVING_R2L]      = _poscalc.MovingPosCalculator:new()
        calcs[_coreconstants.LAYER_STATIC_TOP]      = _poscalc.StaticPosCalculator:new()
        calcs[_coreconstants.LAYER_STATIC_BOTTOM]   = _poscalc.StaticPosCalculator:new()
        calcs[_coreconstants.LAYER_SUBTITLE]        = _poscalc.StaticPosCalculator:new()

        local posFuncs = self._mWritePosFunctions
        posFuncs[_coreconstants.LAYER_MOVING_L2R]       = _writeMovingL2RPos
        posFuncs[_coreconstants.LAYER_MOVING_R2L]       = _writeMovingR2LPos
        posFuncs[_coreconstants.LAYER_STATIC_TOP]       = _writeStaticTopPos
        posFuncs[_coreconstants.LAYER_STATIC_BOTTOM]    = _writeStaticBottomPos
        posFuncs[_coreconstants.LAYER_SUBTITLE]         = _writeBottomSubtitlePos
    end,


    dispose = function(self)
        utils.forEachTableValue(self._mCalculators, utils.disposeSafely)
    end,


    writeDanmakus = function(self, pools, cfg, screenW, screenH, f)
        local hasDanmaku = false
        local calculators = self._mCalculators
        for layer, calc in pairs(calculators)
        do
            local pool = pools:getDanmakuPoolByLayer(layer)
            pool:freeze()
            hasDanmaku = hasDanmaku or pool:getDanmakuCount() > 0
        end

        if not hasDanmaku
        then
            return false
        end

        _ass.writeScriptInfo(f, screenW, screenH)
        _ass.writeStyleHeader(f)
        _ass.writeDanmakuStyle(f, cfg.modifyDanmakuStyleHook, cfg.danmakuFontName, cfg.danmakuFontSize, cfg.danmakuFontColor)
        _ass.writeSubtitleStyle(f, cfg.modifySubtitleStyleHook, cfg.subtitleFontName, cfg.subtitleFontSize, cfg.subtitleFontColor)
        _ass.writeEventsHeader(f)


        local danmakuData = self.__mDanmakuData
        local writePosFuncs = self._mWritePosFunctions
        local builder = self._mDialogueBuilder
        builder:clear()

        for layer, calc in pairs(calculators)
        do
            if layer == _coreconstants.LAYER_SUBTITLE
            then
                builder:initSubtitleStyle()
                calc:init(screenW, screenH - cfg.subtitleReservedBottomHeight)
            else
                builder:initDanmakuStyle()
                calc:init(screenW, screenH - cfg.danmakuReservedBottomHeight)
            end

            local writePosFunc = writePosFuncs[layer]
            local pool = pools:getDanmakuPoolByLayer(layer)
            for i = 1, pool:getDanmakuCount()
            do
                utils.clearTable(danmakuData)
                pool:getDanmakuByIndex(i, danmakuData)

                local startTime = danmakuData.startTime
                local lifeTime = danmakuData.lifeTime
                local fontSize = danmakuData.fontSize
                local danmakuText = danmakuData.danmakuText
                local w, h = _measureDanmakuText(danmakuText, fontSize)
                local y = calc:calculate(w, h, startTime, lifeTime)

                builder:startDialogue(layer, startTime, startTime + lifeTime)
                builder:startStyle()
                builder:addFontColor(danmakuData.fontColor)
                builder:addFontSize(fontSize)
                writePosFunc(cfg, builder, screenW, screenH, w, y)
                builder:endStyle()
                builder:addText(danmakuText)
                builder:endDialogue()
                builder:flushContent(f)
            end
        end

        return true
    end,
}

classlite.declareClass(DanmakuWriter)


return
{
    DanmakuWriter   = DanmakuWriter,
}

-------------------------- src/core/_writer.lua <END> --------------------------

            end
            requestedModule = src_core__writer_lua()
            __loadedModules[path] = requestedModule
        end
        return requestedModule
    end
    if path == "src/core/danmaku"
    then
        local requestedModule = __loadedModules[path]
        if not requestedModule
        then
            local function src_core_danmaku_lua()


------------------------- src/core/danmaku.lua <START> -------------------------
local _coreconstants    = require("src/core/_coreconstants")
local types             = require("src/base/types")
local classlite         = require("src/base/classlite")


local DanmakuSourceID =
{
    _value          = classlite.declareConstantField(0),
    pluginName      = classlite.declareConstantField(nil),
    videoID         = classlite.declareConstantField(nil),
    videoPartIndex  = classlite.declareConstantField(1),
    startTimeOffset = classlite.declareConstantField(0),
    filePath        = classlite.declareConstantField(nil),

    _isSame = function(self, sourceID)
        if self == sourceID
        then
            return true
        end

        return classlite.isInstanceOf(sourceID, self:getClass())
            and self.pluginName == sourceID.pluginName
            and self.videoID == sourceID.videoID
            and self.videoPartIndex == sourceID.videoPartIndex
            and self.startTimeOffset == sourceID.startTimeOffset
            and self.filePath == sourceID.filePath
    end,
}

classlite.declareClass(DanmakuSourceID)


local DanmakuData =
{
    starTime        = classlite.declareConstantField(0),
    lifeTime        = classlite.declareConstantField(0),
    fontColor       = classlite.declareConstantField(0),
    fontSize        = classlite.declareConstantField(0),
    sourceID        = classlite.declareConstantField(nil),
    danmakuID       = classlite.declareConstantField(nil),
    danmakuText     = classlite.declareConstantField(nil),


    _isValid = function(self)
        return types.isNonNegativeNumber(self.startTime)
            and types.isPositiveNumber(self.lifeTime)
            and types.isNonNegativeNumber(self.fontColor)
            and types.isPositiveNumber(self.fontSize)
            and classlite.isInstanceOf(self.sourceID, DanmakuSourceID)
            and self.danmakuID
            and types.isString(self.danmakuText)
    end,


    _appendToDanmakuPool = function(self, poolArrays)
        table.insert(poolArrays[_coreconstants._DANMAKU_IDX_START_TIME],    self.startTime)
        table.insert(poolArrays[_coreconstants._DANMAKU_IDX_LIFE_TIME],     self.lifeTime)
        table.insert(poolArrays[_coreconstants._DANMAKU_IDX_FONT_COLOR],    self.fontColor)
        table.insert(poolArrays[_coreconstants._DANMAKU_IDX_FONT_SIZE],     self.fontSize)
        table.insert(poolArrays[_coreconstants._DANMAKU_IDX_SOURCE_ID],     self.sourceID)
        table.insert(poolArrays[_coreconstants._DANMAKU_IDX_DANMAKU_ID],    self.danmakuID)
        table.insert(poolArrays[_coreconstants._DANMAKU_IDX_DANMAKU_TEXT],  self.danmakuText)
    end,


    _readFromDanmakuPool = function(self, poolArrays, idx)
        self.startTime      = poolArrays[_coreconstants._DANMAKU_IDX_START_TIME][idx]
        self.lifeTime       = poolArrays[_coreconstants._DANMAKU_IDX_LIFE_TIME][idx]
        self.fontColor      = poolArrays[_coreconstants._DANMAKU_IDX_FONT_COLOR][idx]
        self.fontSize       = poolArrays[_coreconstants._DANMAKU_IDX_FONT_SIZE][idx]
        self.sourceID       = poolArrays[_coreconstants._DANMAKU_IDX_SOURCE_ID][idx]
        self.danmakuID      = poolArrays[_coreconstants._DANMAKU_IDX_DANMAKU_ID][idx]
        self.danmakuText    = poolArrays[_coreconstants._DANMAKU_IDX_DANMAKU_TEXT][idx]
    end,
}

classlite.declareClass(DanmakuData)


return
{
    DanmakuSourceID = DanmakuSourceID,
    DanmakuData     = DanmakuData,
}
-------------------------- src/core/danmaku.lua <END> --------------------------

            end
            requestedModule = src_core_danmaku_lua()
            __loadedModules[path] = requestedModule
        end
        return requestedModule
    end
    if path == "src/core/danmakupool"
    then
        local requestedModule = __loadedModules[path]
        if not requestedModule
        then
            local function src_core_danmakupool_lua()


----------------------- src/core/danmakupool.lua <START> -----------------------
local _ass              = require("src/core/_ass")
local _writer           = require("src/core/_writer")
local _coreconstants    = require("src/core/_coreconstants")
local types             = require("src/base/types")
local utils             = require("src/base/utils")
local constants         = require("src/base/constants")
local classlite         = require("src/base/classlite")
local danmaku           = require("src/core/danmaku")


local DanmakuPool =
{
    _mDanmakuDataArrays         = classlite.declareTableField(),
    _mDanmakuIndexes            = classlite.declareTableField(),
    _mModifyDanmakuDataHook     = classlite.declareConstantField(nil),
    __mCompareFunc              = classlite.declareConstantField(nil),

    new = function(self)
        local arrays = self._mDanmakuDataArrays
        for i = 1, _coreconstants._DANMAKU_IDX_MAX
        do
            arrays[i] = {}
        end

        self.__mCompareFunc = function(idx1, idx2)
            local function __compareString(str1, str2)
                if str1 == str2
                then
                    return 0
                else
                    return str1 < str2 and -1 or 1
                end
            end


            local ret = 0
            local arrays = self._mDanmakuDataArrays
            local startTimes = arrays[_coreconstants._DANMAKU_IDX_START_TIME]
            local sourceIDs = arrays[_coreconstants._DANMAKU_IDX_SOURCE_ID]
            local danmakuIDs = arrays[_coreconstants._DANMAKU_IDX_DANMAKU_ID]
            ret = ret ~= 0 and ret or startTimes[idx1] - startTimes[idx2]
            ret = ret ~= 0 and ret or sourceIDs[idx1]._value - sourceIDs[idx2]._value
            ret = ret ~= 0 and ret or __compareString(danmakuIDs[idx1], danmakuIDs[idx2])
            return ret < 0
        end
    end,

    dispose = function(self)
        self:clear()
    end,

    setModifyDanmakuDataHook = function(self, hook)
        self._mModifyDanmakuDataHook = types.isFunction(hook) and hook
    end,

    getDanmakuCount = function(self)
        return #self._mDanmakuIndexes
    end,

    getDanmakuByIndex = function(self, idx, outData)
        local sortedIdx = self._mDanmakuIndexes[idx]
        outData:_readFromDanmakuPool(self._mDanmakuDataArrays, sortedIdx)
    end,


    addDanmaku = function(self, danmakuData)
        -- 钩子函数返回 true 才认为是过滤，因为 pcall 返回 false 表示调用失败
        local hook = self._mModifyDanmakuDataHook
        if hook and pcall(hook, danmakuData)
        then
            return
        end

        if danmakuData:_isValid()
        then
            danmakuData:_appendToDanmakuPool(self._mDanmakuDataArrays)
            table.insert(self._mDanmakuIndexes, self:getDanmakuCount() + 1)
        end
    end,


    freeze = function(self)
        local arrays = self._mDanmakuDataArrays
        local sourceIDs = arrays[_coreconstants._DANMAKU_IDX_SOURCE_ID]
        local danmakuIDs = arrays[_coreconstants._DANMAKU_IDX_DANMAKU_ID]
        local indexes = self._mDanmakuIndexes
        table.sort(indexes, self.__mCompareFunc)

        -- 去重
        local writeIdx = 1
        local prevDanmakuID = nil
        local prevSourceIDValue = math.huge
        for _, idx in ipairs(indexes)
        do
            local curDanmakuID = danmakuIDs[idx]
            local curSourceIDValue = sourceIDs[idx]._value
            if curDanmakuID ~= prevDanmakuID or curSourceIDValue ~= prevSourceIDValue
            then
                indexes[writeIdx] = idx
                writeIdx = writeIdx + 1
                prevDanmakuID = curDanmakuID
                prevSourceIDValue = curSourceIDValue
            end
        end

        -- 如果有重复数组长度会比原来的短，不要删平行数组的数据，因为索引没整理过
        utils.clearArray(indexes, writeIdx)
    end,


    clear = function(self)
        utils.forEachTableValue(self._mDanmakuDataArrays, utils.clearTable)
        utils.clearTable(self._mDanmakuIndexes)
    end,
}

classlite.declareClass(DanmakuPool)


local DanmakuPools =
{
    _mPools                 = classlite.declareTableField(),
    _mWriter                = classlite.declareClassField(_writer.DanmakuWriter),
    _mSourceIDPool          = classlite.declareTableField(),
    _mSourceIDCount         = classlite.declareConstantField(0),
    _mCompareSourceIDHook   = classlite.declareConstantField(nil),

    new = function(self)
        local pools = self._mPools
        pools[_coreconstants.LAYER_MOVING_L2R]      = DanmakuPool:new()
        pools[_coreconstants.LAYER_MOVING_R2L]      = DanmakuPool:new()
        pools[_coreconstants.LAYER_STATIC_TOP]      = DanmakuPool:new()
        pools[_coreconstants.LAYER_STATIC_BOTTOM]   = DanmakuPool:new()
        pools[_coreconstants.LAYER_ADVANCED]        = DanmakuPool:new()
        pools[_coreconstants.LAYER_SUBTITLE]        = DanmakuPool:new()
    end,

    dispose = function(self)
        utils.forEachArrayElement(self._mSourceIDPool, utils.disposeSafely)
        self:clear()
    end,

    setCompareSourceIDHook = function(self, hook)
        self._mCompareSourceIDHook = types.isFunction(hook) and hook
    end,

    iteratePools = function(self)
        return ipairs(self._mPools)
    end,

    getDanmakuPoolByLayer = function(self, layer)
        return layer and self._mPools[layer]
    end,

    allocateDanmakuSourceID = function(self, pluginName, videoID, partIdx, offset, filePath)
        local function __iterateSourceIDs(pool, count, hook, arg, sourceID)
            for i = 1, count
            do
                local iterSourceID = pool[i]
                if hook(arg, sourceID, iterSourceID)
                then
                    sourceID._value = iterSourceID._value
                    return iterSourceID
                end
            end
        end

        local function __checkIsSame(_, sourceID, iterSourceID)
            return iterSourceID:_isSame(sourceID)
        end

        local function __checkIsSameByHook(hook, sourceID, iterSouceID)
            return pcall(hook, sourceID, iterSouceID)
        end


        local pool = self._mSourceIDPool
        local count = self._mSourceIDCount
        local sourceID = pool[count]
        if not sourceID
        then
            sourceID = danmaku.DanmakuSourceID:new()
            pool[count] = sourceID
        end

        sourceID.pluginName = pluginName
        sourceID.videoID = videoID
        sourceID.videoPartIndex = partIdx
        sourceID.startTimeOffset = offset
        sourceID.filePath = filePath

        -- 有可能之前就构造过一模一样的实例
        local ret1 = __iterateSourceIDs(pool, count, __checkIsSame, nil, sourceID)
        if ret1
        then
            return ret1
        end

        -- 例如同一个 cid 的不同历史版本，虽然文件路径不同，但也应被认为是同一个弹幕源
        local hook = self._mCompareSourceIDHook
        local ret2 = hook and __iterateSourceIDs(pool, count, __checkIsSameByHook, hook, sourceID)
        if ret2
        then
            return ret2
        end

        self._mSourceIDCount = count + 1
        return sourceID
    end,

    writeDanmakus = function(self, app, f)
        local cfg = app:getConfiguration()
        local width = cfg.danmakuResolutionX
        local height = cfg.danmakuResolutionY
        return self._mWriter:writeDanmakus(self, cfg, width, height, f)
    end,

    clear = function(self)
        self._mSourceIDCount = 0
        utils.forEachTableValue(self._mPools, DanmakuPool.clear)
    end,
}

classlite.declareClass(DanmakuPools)


return
{
    LAYER_MOVING_L2R        = _coreconstants.LAYER_MOVING_L2R,
    LAYER_MOVING_R2L        = _coreconstants.LAYER_MOVING_R2L,
    LAYER_STATIC_TOP        = _coreconstants.LAYER_STATIC_TOP,
    LAYER_STATIC_BOTTOM     = _coreconstants.LAYER_STATIC_BOTTOM,
    LAYER_ADVANCED          = _coreconstants.LAYER_ADVANCED,
    LAYER_SUBTITLE          = _coreconstants.LAYER_SUBTITLE,
    LAYER_SKIPPED           = _coreconstants.LAYER_SKIPPED,

    DanmakuPools            = DanmakuPools,
}

------------------------ src/core/danmakupool.lua <END> ------------------------

            end
            requestedModule = src_core_danmakupool_lua()
            __loadedModules[path] = requestedModule
        end
        return requestedModule
    end
    if path == "src/plugins/acfun"
    then
        local requestedModule = __loadedModules[path]
        if not requestedModule
        then
            local function src_plugins_acfun_lua()


------------------------ src/plugins/acfun.lua <START> -------------------------
local types         = require("src/base/types")
local utils         = require("src/base/utils")
local constants     = require("src/base/constants")
local classlite     = require("src/base/classlite")
local danmakupool   = require("src/core/danmakupool")
local pluginbase    = require("src/plugins/pluginbase")


local _ACFUN_PLUGIN_NAME                = "Acfun"

local _ACFUN_DEFAULT_DURATION           = 0
local _ACFUN_FACTOR_TIME_STAMP          = 1000

local _ACFUN_DEFAULT_VIDEO_INDEX        = 1

local _ACFUN_PATTERN_VID                = '<a%s*data-vid="([%d]+)"'
local _ACFUN_PATTERN_DURATION           = '"time"%s*:%s*([%d]+)%s*,'
local _ACFUN_PATTERN_DANMAKU_INFO_KEY   = '"c"%s*:%s*'
local _ACFUN_PATTERN_DANMAKU_TEXT_KEY   = '"m"%s*:%s*'
local _ACFUN_PATTERN_DANMAKU_INFO_VALUE = "([%d%.]+),"     -- 出现时间
                                          .. "(%d+),"      -- 颜色
                                          .. "(%d+),"      -- 弹幕类型
                                          .. "(%d+),"      -- 字体大小
                                          .. "[^,]+,"      -- 用户 ID ？
                                          .. "(%d+),"      -- 弹幕 ID ？
                                          .. "[^,]+"        -- hash ？

local _ACFUN_PATTERN_TITLE_1P           = "<h2>(.-)</h2>"
local _ACFUN_PATTERN_VID_AND_TITLE      = '<a%s+data%-vid="(%d+)".->(.-)</a>'
local _ACFUN_PATTERN_SANITIZE_TITLE     = "<i.-</i>"

local _ACFUN_PATTERN_SEARCH_URL         = "http://www.acfun.tv/v/ac([%d_]+)"
local _ACFUN_PATTERN_SEARCH_ACID        = "acfun:ac([%d_]+)"
local _ACFUN_PATTERN_SEARCH_VID         = "acfun:vid(%d+)"
local _ACFUN_PATTERN_SEARCH_PART_INDEX  = "^%d*_(%d+)$"

local _ACFUN_FMT_URL_VIDEO              = "http://www.acfun.tv/v/ac%s"
local _ACFUN_FMT_URL_DANMAKU            = "http://danmu.aixifan.com/V2/%s"
local _ACFUN_FMT_URL_VIDEO_INFO         = "http://www.acfun.tv/video/getVideo.aspx?id=%s"
local _ACFUN_FMT_SEARCH_VID_TITLE       = "vid%s"


local _ACFUN_POS_TO_LAYER_MAP   =
{
    [1] = danmakupool.LAYER_MOVING_R2L,
    [2] = danmakupool.LAYER_MOVING_R2L,
    [4] = danmakupool.LAYER_STATIC_TOP,
    [5] = danmakupool.LAYER_STATIC_BOTTOM,
}


local AcfunDanmakuSourcePlugin =
{
    __mVideoTitles      = classlite.declareTableField(),


    getName = function(self)
        return _ACFUN_PLUGIN_NAME
    end,

    search = function(self, input, result)
        local vid = input:match(_ACFUN_PATTERN_SEARCH_VID)
        if vid
        then
            result.isSplited = false
            result.preferredIDIndex = _ACFUN_DEFAULT_DURATION
            table.insert(result.videoIDs, vid)
            table.insert(result.videoTitles, string.format(_ACFUN_FMT_SEARCH_VID_TITLE, vid))
        else
            local acid = input:match(_ACFUN_PATTERN_SEARCH_URL)
            acid = acid or input:match(_ACFUN_PATTERN_SEARCH_ACID)
            if not acid
            then
                return false
            end

            local conn = self._mApplication:getNetworkConnection()
            conn:clearHeaders()
            conn:addHeader(pluginbase._HEADER_USER_AGENT)

            local url = string.format(_ACFUN_FMT_URL_VIDEO, acid)
            local data = conn:receive(url)
            if not data
            then
                return false
            end


            local partCount = 0
            local titles = utils.clearTable(self.__mVideoTitles)
            for vid, title in data:gmatch(_ACFUN_PATTERN_VID_AND_TITLE)
            do
                title = title:gsub(_ACFUN_PATTERN_SANITIZE_TITLE, constants.STR_EMPTY)
                title = utils.unescapeXMLString(title)
                partCount = partCount + 1
                table.insert(titles, title)
                table.insert(result.videoIDs, vid)
            end

            if partCount <= 0
            then
                return false
            elseif partCount == 1
            then
                local title = data:match(_ACFUN_PATTERN_TITLE_1P)
                if not title
                then
                    return false
                end

                title = utils.unescapeXMLString(title)
                table.insert(result.videoTitles, title)
            else
                utils.appendArrayElements(result.videoTitles, titles)
            end

            local partIdx = acid:match(_ACFUN_PATTERN_SEARCH_PART_INDEX)
            partIdx = partIdx and tonumber(partIdx)
            result.isSplited = partCount > 1
            result.preferredIDIndex = partIdx or _ACFUN_DEFAULT_VIDEO_INDEX
        end

        result.videoTitleColumnCount = 1
        return true
    end,


    _startExtractDanmakus = function(self, rawData)
        -- 用闭包函数模仿 string.gmatch() 的行为
        local startIdx = 1
        local ret = function()
            local findIdx = startIdx
            local _, endIdx1 = rawData:find(_ACFUN_PATTERN_DANMAKU_INFO_KEY, findIdx, false)
            if not endIdx1
            then
                return
            end

            findIdx = endIdx1 + 1
            local posText, endIdx2 = utils.findJSONString(rawData, findIdx)
            local start, color, layer, size, id = posText:match(_ACFUN_PATTERN_DANMAKU_INFO_VALUE)
            if not endIdx2
            then
                return
            end

            findIdx = endIdx2 + 1
            local _, endIdx3 = rawData:find(_ACFUN_PATTERN_DANMAKU_TEXT_KEY, findIdx, false)
            if not endIdx3
            then
                return
            end

            findIdx = endIdx3 + 1
            local text, nextFindIdx = utils.findJSONString(rawData, findIdx)
            if not nextFindIdx
            then
                return
            end

            startIdx = nextFindIdx
            return text, start, color, layer, size, id
        end
        return ret
    end,

    _extractDanmaku = function(self, iterFunc, cfg, danmakuData)
        local text, startTime, fontColor, layer, fontSize, danmakuID = iterFunc()
        if not text
        then
            return
        end

        danmakuData.startTime = tonumber(startTime * _ACFUN_FACTOR_TIME_STAMP)
        danmakuData.fontSize = tonumber(fontSize)
        danmakuData.fontColor = tonumber(fontColor)
        danmakuData.danmakuID = tonumber(danmakuID)
        danmakuData.danmakuText = text
        return _ACFUN_POS_TO_LAYER_MAP[tonumber(layer)] or danmakupool.LAYER_SKIPPED
    end,

    __initNetworkConnection = function(self, conn)
        conn:clearHeaders()
        conn:addHeader(pluginbase._HEADER_USER_AGENT)
        conn:setCompressed(true)
    end,


    _doDownloadDanmakuRawData = function(self, conn, videoID, outDatas)
        self:__initNetworkConnection(conn)
        return string.format(_ACFUN_FMT_URL_DANMAKU, videoID)
    end,


    _doGetVideoDuration = function(self, conn, videoID, outDurations)
        local function __parseDuration(data, outDurations)
            local duration = nil
            if types.isString(data)
            then
                local seconds = data:match(_ACFUN_PATTERN_DURATION)
                duration = seconds and utils.convertHHMMSSToTime(0, 0, tonumber(seconds), 0)
            end
            duration = duration or _ACFUN_DEFAULT_DURATION
            table.insert(outDurations, duration)
        end

        local url = string.format(_ACFUN_FMT_URL_VIDEO_INFO, videoID)
        self:__initNetworkConnection(conn)
        conn:receiveLater(url, __parseDuration, outDurations)
    end,
}

classlite.declareClass(AcfunDanmakuSourcePlugin, pluginbase._PatternBasedDanmakuSourcePlugin)


return
{
    AcfunDanmakuSourcePlugin    = AcfunDanmakuSourcePlugin,
}
------------------------- src/plugins/acfun.lua <END> --------------------------

            end
            requestedModule = src_plugins_acfun_lua()
            __loadedModules[path] = requestedModule
        end
        return requestedModule
    end
    if path == "src/plugins/bilibili"
    then
        local requestedModule = __loadedModules[path]
        if not requestedModule
        then
            local function src_plugins_bilibili_lua()


----------------------- src/plugins/bilibili.lua <START> -----------------------
local types         = require("src/base/types")
local utils         = require("src/base/utils")
local constants     = require("src/base/constants")
local classlite     = require("src/base/classlite")
local danmakupool   = require("src/core/danmakupool")
local pluginbase    = require("src/plugins/pluginbase")


local _BILI_PLUGIN_NAME         = "BiliBili"

local _BILI_PATTERN_DANMAKU     = '<d%s+p="'
                                  .. "([%d%.]+),"       -- 起始时间
                                  .. "(%d+),"           -- 移动类型
                                  .. "(%d+),"           -- 字体大小
                                  .. "(%d+),"           -- 字体颜色
                                  .. "[^>]+,"
                                  .. "[^>]+,"           -- 据说是 弹幕池 ID ，但一股都是 0
                                  .. "[^>]+,"
                                  .. "(%d+)"            -- 弹幕 ID
                                  .. '">([^<]+)</d>'

local _BILI_PATTERN_DURATION    = "<duration>(%d+):?(%d+)</duration>"
local _BILI_PATTERN_TITLE_1P    = "<title>(.-)</title>"
local _BILI_PATTERN_TITLE_NP    = "<option value=.->%d+、(.-)</option>"
local _BILI_PATTERN_CID_1       = "EmbedPlayer%(.-cid=(%d+).-%)"
local _BILI_PATTERN_CID_2       = '<iframe.-src=".-cid=(%d+).-"'
local _BILI_PATTERN_SANITIZE    = "[\x00-\x08\x0b\x0c\x0e-\x1f]"

local _BILI_FMT_URL_VIDEO_1P    = "http://www.bilibili.com/video/av%s/"
local _BILI_FMT_URL_VIDEO_NP    = "http://www.bilibili.com/video/av%s/index_%d.html"
local _BILI_FMT_URL_DAMAKU      = "http://comment.bilibili.com/%s.xml"
local _BILI_FMT_URL_VIDEO_INFO  = "http://interface.bilibili.com/player?id=cid:%s"


local _BILI_PATTERN_SEARCH_URL_1P   = "www%.bilibili%.[^/]*/video/av(%d+)"
local _BILI_PATTERN_SERCH_URL_NP    = "www%.bilibili%.[^/]*/video/av(%d+)/index_(%d*).html"
local _BILI_PATTERN_SEARCH_AVID     = "bili:av(%d+)"
local _BILI_PATTERN_SEARCH_CID      = "bili:cid(%d+)"

local _BILI_FMT_SEARCH_CID_TITLE    = "cid%s"

local _BILI_CONST_NEWLINE           = "/n"

local _BILI_FACTOR_TIME_STAMP       = 1000
local _BILI_FACTOR_FONT_SIZE        = 25

local _BILI_DEFAULT_DURATION        = 0
local _BILI_DEFAULT_VIDEO_INDEX     = 1

-- 暂时不处理神弹幕
local _BILI_POS_TO_LAYER_MAP =
{
    [6] = danmakupool.LAYER_MOVING_L2R,
    [1] = danmakupool.LAYER_MOVING_R2L,
    [5] = danmakupool.LAYER_STATIC_TOP,
    [4] = danmakupool.LAYER_STATIC_BOTTOM,
}


local function __sanitizeString(str)
    return str:gsub(_BILI_PATTERN_SANITIZE, constants.STR_EMPTY)
end


local BiliBiliDanmakuSourcePlugin =
{
    getName = function(self)
        return _BILI_PLUGIN_NAME
    end,

    _startExtractDanmakus = function(self, rawData)
        return rawData:gmatch(_BILI_PATTERN_DANMAKU)
    end,

    _extractDanmaku = function(self, iterFunc, cfg, danmakuData)
        local startTime, layer, fontSize, fontColor, danmakuID, text = iterFunc()
        if not startTime
        then
            return
        end

        local size = math.floor(tonumber(fontSize) / _BILI_FACTOR_FONT_SIZE * cfg.danmakuFontSize)
        local text = utils.unescapeXMLString(__sanitizeString(text))
        text = text:gsub(_BILI_CONST_NEWLINE, constants.STR_NEWLINE)
        danmakuData.fontSize = size
        danmakuData.fontColor = tonumber(fontColor)
        danmakuData.startTime = tonumber(startTime) * _BILI_FACTOR_TIME_STAMP
        danmakuData.danmakuID = tonumber(danmakuID)
        danmakuData.danmakuText = text
        return _BILI_POS_TO_LAYER_MAP[tonumber(layer)] or danmakupool.LAYER_SKIPPED
    end,


    search = function(self, keyword, result)
        local function __getVideoIDAndIndex(keyword)
            local id, idx = keyword:match(_BILI_PATTERN_SERCH_URL_NP)
            id = id or keyword:match(_BILI_PATTERN_SEARCH_URL_1P)
            id = id or keyword:match(_BILI_PATTERN_SEARCH_AVID)
            idx = idx and tonumber(idx) or _BILI_DEFAULT_VIDEO_INDEX
            return id, idx
        end

        local function __parseCID(data, outCIDs)
            local cid = data:match(_BILI_PATTERN_CID_1)
            cid = cid or data:match(_BILI_PATTERN_CID_2)
            utils.pushArrayElement(outCIDs, cid)
        end

        local cid = keyword:match(_BILI_PATTERN_SEARCH_CID)
        if cid
        then
            result.isSplited = false
            result.preferredIDIndex = _BILI_DEFAULT_VIDEO_INDEX
            table.insert(result.videoIDs, cid)
            table.insert(result.videoTitles, string.format(_BILI_FMT_SEARCH_CID_TITLE, cid))
        else
            local avID, index = __getVideoIDAndIndex(keyword)
            if not avID
            then
                return false
            end
            result.preferredIDIndex = index

            local conn = self._mApplication:getNetworkConnection()
            conn:clearHeaders()
            conn:addHeader(pluginbase._HEADER_USER_AGENT)
            conn:setCompressed(true)

            local data = conn:receive(string.format(_BILI_FMT_URL_VIDEO_1P, avID))
            if not data
            then
                return false
            end

            -- 分P视频
            local partIdx = 1
            for partName in data:gmatch(_BILI_PATTERN_TITLE_NP)
            do
                partName = __sanitizeString(partName)
                partName = utils.unescapeXMLString(partName)
                if partIdx == 1
                then
                    __parseCID(data, result.videoIDs)
                else
                    local url = string.format(_BILI_FMT_URL_VIDEO_NP, avID, partIdx)
                    conn:receiveLater(url, __parseCID, result.videoIDs)
                end
                partIdx = partIdx + 1
                table.insert(result.videoTitles, partName)
            end
            conn:flushReceiveQueue()

            -- 单P视频
            if partIdx == 1
            then
                local title = data:match(_BILI_PATTERN_TITLE_1P)
                title = __sanitizeString(title)
                title = utils.unescapeXMLString(title)
                table.insert(result.videoTitles, title)
                __parseCID(data, result.videoIDs)
            end

            result.isSplited = (partIdx > 1)
        end

        result.videoTitleColumnCount = 1
        return #result.videoIDs > 0 and #result.videoIDs == #result.videoTitles
    end,

    __initNetworkConnection = function(self, conn)
        conn:clearHeaders()
        conn:addHeader(pluginbase._HEADER_USER_AGENT)
        conn:addHeader(pluginbase._HEADER_ACCEPT_XML)
        conn:setCompressed(true)
    end,


    _doDownloadDanmakuRawData = function(self, conn, videoID, outDatas)
        self:__initNetworkConnection(conn)
        return string.format(_BILI_FMT_URL_DAMAKU, videoID)
    end,


    _doGetVideoDuration = function(self, conn, videoID, outDurations)
        local function __parseDuration(rawData, outDurations)
            local duration = _BILI_DEFAULT_DURATION
            if types.isString(rawData)
            then
                -- 时频长度一般以 "MM:SS" 表示
                -- 例如少于 1 分钟的视频，会不会用 "SS" 格式？
                local piece1, piece2 = rawData:match(_BILI_PATTERN_DURATION)
                if piece1 or piece2
                then
                    local minutes = (piece1 and piece2) and piece1 or 0
                    local seconds = piece2 or piece1
                    minutes = tonumber(minutes)
                    seconds = tonumber(seconds)
                    duration = utils.convertHHMMSSToTime(0, minutes, seconds, 0)
                end
            end
            table.insert(outDurations, duration)
        end

        local url = string.format(_BILI_FMT_URL_VIDEO_INFO, videoID)
        self:__initNetworkConnection(conn)
        conn:receiveLater(url, __parseDuration, outDurations)
    end,
}

classlite.declareClass(BiliBiliDanmakuSourcePlugin, pluginbase._PatternBasedDanmakuSourcePlugin)


return
{
    BiliBiliDanmakuSourcePlugin     = BiliBiliDanmakuSourcePlugin,
}
------------------------ src/plugins/bilibili.lua <END> ------------------------

            end
            requestedModule = src_plugins_bilibili_lua()
            __loadedModules[path] = requestedModule
        end
        return requestedModule
    end
    if path == "src/plugins/dandanplay"
    then
        local requestedModule = __loadedModules[path]
        if not requestedModule
        then
            local function src_plugins_dandanplay_lua()


---------------------- src/plugins/dandanplay.lua <START> ----------------------
local types         = require("src/base/types")
local utils         = require("src/base/utils")
local constants     = require("src/base/constants")
local classlite     = require("src/base/classlite")
local danmakupool   = require("src/core/danmakupool")
local pluginbase    = require("src/plugins/pluginbase")


local _DDP_PLUGIN_NAME              = "DanDanPlay"

local _DDP_FMT_URL_DANMAKU          = "http://acplay.net/api/v1/comment/%s"
local _DDP_FMT_URL_SEARCH           = "http://acplay.net/api/v1/searchall/%s"

local _DDP_PATTERN_VIDEO_TITLE      = '<Anime Title="(.-)"'
local _DDP_PATTERN_EPISODE_TITLE    = '<Episode Id="(%d+)" Title="(.-)"'
local _DDP_PATTERN_SEARCH_KEYWORD   = "ddp:%s*(.+)%s*$"
local _DDP_PATTERN_COMMENT          = "<Comment"
                                      .. '%s+Time="([%d.]+)"'
                                      .. '%s+Mode="(%d+)"'
                                      .. '%s+Color="(%d+)"'
                                      .. '%s+Timestamp="%d+"'
                                      .. '%s+Pool="%d+"'
                                      .. '%s+UId="%-?[%d]+"'
                                      .. '%s+CId="(%d+)"'
                                      .. "%s*>"
                                      .. "([^<]+)"
                                      .. "</Comment>"


local _DDP_FACTOR_TIME_STAMP        = 1000

local _DDP_POS_TO_LAYER_MAP =
{
    [6] = danmakupool.LAYER_MOVING_L2R,
    [1] = danmakupool.LAYER_MOVING_R2L,
    [5] = danmakupool.LAYER_STATIC_TOP,
    [4] = danmakupool.LAYER_STATIC_BOTTOM,
}


local DanDanPlayDanmakuSourcePlugin =
{
    __mVideoIDs         = classlite.declareTableField(),
    __mVideoTitles      = classlite.declareTableField(),
    __mVideoSubtitles   = classlite.declareTableField(),
    __mCaptureIndexes1  = classlite.declareTableField(),
    __mCaptureIndexes2  = classlite.declareTableField(),


    getName = function(self)
        return _DDP_PLUGIN_NAME
    end,

    _startExtractDanmakus = function(self, rawData)
        return rawData:gmatch(_DDP_PATTERN_COMMENT)
    end,

    _extractDanmaku = function(self, iterFunc, cfg, danmakuData)
        local startTime, layer, fontColor, danmakuID, text = iterFunc()
        if not startTime
        then
            return
        end

        danmakuData.startTime = tonumber(startTime) * _DDP_FACTOR_TIME_STAMP
        danmakuData.fontSize = cfg.danmakuFontSize
        danmakuData.fontColor = tonumber(fontColor)
        danmakuData.danmakuID = tonumber(danmakuID)
        danmakuData.danmakuText = utils.unescapeXMLString(text)
        return _DDP_POS_TO_LAYER_MAP[tonumber(layer)] or danmakupool.LAYER_SKIPPED
    end,


    search = function(self, input, result)
        local function __captureIndexesAndStrings(data, pattern, indexes, table1, table2)
            -- 收集匹配的字符串
            for str1, str2 in data:gmatch(pattern)
            do
                utils.pushArrayElement(table1, str1)
                utils.pushArrayElement(table2, str2)
            end

            -- 收集匹配的字符串索引
            local findStartIndex = 1
            while true
            do
                local startIdx, endIdx = data:find(pattern, findStartIndex, false)
                if not startIdx
                then
                    break
                end

                table.insert(indexes, startIdx)
                findStartIndex = endIdx + 1
            end
        end


        local keyword = input:match(_DDP_PATTERN_SEARCH_KEYWORD)
        if not keyword
        then
            return false
        end

        local conn = self._mApplication:getNetworkConnection()
        self:__initNetworkConnection(conn)

        local url = string.format(_DDP_FMT_URL_SEARCH, utils.escapeURLString(keyword))
        local data = conn:receive(url)
        if types.isNilOrEmpty(data)
        then
            return false
        end

        local videoIDs = utils.clearTable(self.__mVideoIDs)
        local titles = utils.clearTable(self.__mVideoTitles)
        local subtitles = utils.clearTable(self.__mVideoSubtitles)
        local indexes1 = utils.clearTable(self.__mCaptureIndexes1)
        local indexes2 = utils.clearTable(self.__mCaptureIndexes2)

        -- 剧集标题
        __captureIndexesAndStrings(data, _DDP_PATTERN_VIDEO_TITLE, indexes1, titles)
        utils.forEachArrayElement(titles, utils.unescapeXMLString)

        -- 分集标题
        __captureIndexesAndStrings(data, _DDP_PATTERN_EPISODE_TITLE, indexes2, videoIDs, subtitles)
        utils.forEachArrayElement(subtitles, utils.unescapeXMLString)

        -- 剧集标题比分集标题出现得早，例如
        -- <Anime Title="刀剑神域" Type="1">
        --     <Episode Id="86920001" Title="第1话 剣の世界"/>
        --     <Episode Id="86920002" Title="第2话 ビーター"/>
        local subtitleIdx = 1
        for titleIdx, title in ipairs(titles)
        do
            local subtitleCaptureIdx = indexes2[subtitleIdx]
            local nextTitleCaptureIdx = #titles > 1 and indexes1[titleIdx + 1] or math.huge
            while subtitleCaptureIdx and subtitleCaptureIdx < nextTitleCaptureIdx
            do
                table.insert(result.videoIDs, videoIDs[subtitleIdx])
                table.insert(result.videoTitles, title)
                table.insert(result.videoTitles, subtitles[subtitleIdx])
                subtitleIdx = subtitleIdx + 1
                subtitleCaptureIdx = indexes2[subtitleIdx]
            end
        end

        result.isSplited = false
        result.videoTitleColumnCount = 2
        result.preferredIDIndex = 1
        return true
    end,


    __initNetworkConnection = function(self, conn)
        conn:clearHeaders()
        conn:addHeader(pluginbase._HEADER_USER_AGENT)
        conn:addHeader(pluginbase._HEADER_ACCEPT_XML)
    end,


    _doDownloadDanmakuRawData = function(self, conn, videoID, outDatas)
        self:__initNetworkConnection(conn)
        return string.format(_DDP_FMT_URL_DANMAKU, videoID)
    end,
}

classlite.declareClass(DanDanPlayDanmakuSourcePlugin, pluginbase._PatternBasedDanmakuSourcePlugin)


return
{
    DanDanPlayDanmakuSourcePlugin   = DanDanPlayDanmakuSourcePlugin,
}
----------------------- src/plugins/dandanplay.lua <END> -----------------------

            end
            requestedModule = src_plugins_dandanplay_lua()
            __loadedModules[path] = requestedModule
        end
        return requestedModule
    end
    if path == "src/plugins/pluginbase"
    then
        local requestedModule = __loadedModules[path]
        if not requestedModule
        then
            local function src_plugins_pluginbase_lua()


---------------------- src/plugins/pluginbase.lua <START> ----------------------
local utils         = require("src/base/utils")
local types         = require("src/base/types")
local constants     = require("src/base/constants")
local classlite     = require("src/base/classlite")
local danmaku       = require("src/core/danmaku")
local danmakupool   = require("src/core/danmakupool")


local _HEADER_USER_AGENT    = "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:44.0) Gecko/20100101 Firefox/44.0"
local _HEADER_ACCEPT_XML    = "Accept: application/xml"


local IDanmakuSourcePlugin =
{
    _mApplication   = classlite.declareConstantField(nil),

    setApplication = function(self, app)
        self._mApplication = app
    end,

    getName = constants.FUNC_EMPTY,
    parseFile = constants.FUNC_EMPTY,
    parseData = constants.FUNC_EMPTY,
    search = constants.FUNC_EMPTY,
    getVideoDurations = constants.FUNC_EMPTY,
    downloadDanmakuRawDatas = constants.FUNC_EMPTY,
}

classlite.declareClass(IDanmakuSourcePlugin)


local function __doInvokeVideoIDsBasedMethod(self, videoIDs, outList, iterFunc)
    local function __appendResult(ret, outList)
        table.insert(outList, ret)
    end

    if types.isTable(videoIDs) and types.isTable(outList)
    then
        local conn = self._mApplication:getNetworkConnection()
        for _, videoID in ipairs(videoIDs)
        do
            local ret = iterFunc(self, conn, videoID, outList)
            if types.isString(ret)
            then
                conn:receiveLater(ret, __appendResult, outList)
            end
        end
        conn:flushReceiveQueue()
    end
end


local _AbstractDanmakuSourcePlugin =
{
    _doDownloadDanmakuRawData = constants.FUNC_EMPTY,
    _doGetVideoDuration = constants.FUNC_EMPTY,

    parseFile = function(self, filePath, ...)
        local file = self._mApplication:readUTF8File(filePath)
        local rawData = utils.readAndCloseFile(file)
        return rawData and self:parseData(rawData, ...)
    end,

    downloadDanmakuRawDatas = function(self, videoIDs, outDatas)
        local iterFunc = self._doDownloadDanmakuRawData
        return __doInvokeVideoIDsBasedMethod(self, videoIDs, outDatas, iterFunc)
    end,

    getVideoDurations = function(self, videoIDs, outDurations)
        local iterFunc = self._doGetVideoDuration
        return __doInvokeVideoIDsBasedMethod(self, videoIDs, outDurations, iterFunc)
    end,
}

classlite.declareClass(_AbstractDanmakuSourcePlugin, IDanmakuSourcePlugin)


local _PatternBasedDanmakuSourcePlugin =
{
    __mDanmakuData     = classlite.declareClassField(danmaku.DanmakuData),


    _extractDanmaku = constants.FUNC_EMPTY,
    _startExtractDanmakus = constants.FUNC_EMPTY,

    _getLifeTimeByLayer = function(self, cfg, pos)
        if pos == danmakupool.LAYER_MOVING_L2R or pos == danmakupool.LAYER_MOVING_R2L
        then
            return cfg.movingDanmakuLifeTime
        elseif pos == danmakupool.LAYER_STATIC_TOP or pos == danmakupool.LAYER_STATIC_BOTTOM
        then
            return cfg.staticDanmakuLIfeTime
        else
            -- 依靠弹幕池的参数检查来过滤
        end
    end,


    parseData = function(self, rawData, sourceID, timeOffset)
        local app = self._mApplication
        local pools = app:getDanmakuPools()
        local cfg = app:getConfiguration()
        local iterFunc = self:_startExtractDanmakus(rawData)
        local danmakuData = self.__mDanmakuData
        timeOffset = timeOffset or 0
        while true
        do
            local layer = self:_extractDanmaku(iterFunc, cfg, danmakuData)
            if not layer
            then
                break
            end

            danmakuData.startTime = danmakuData.startTime + timeOffset
            danmakuData.lifeTime = self:_getLifeTimeByLayer(cfg, layer)
            danmakuData.sourceID = sourceID

            local pool = pools:getDanmakuPoolByLayer(layer)
            if pool
            then
                pool:addDanmaku(danmakuData)
            end
        end
    end,
}

classlite.declareClass(_PatternBasedDanmakuSourcePlugin, _AbstractDanmakuSourcePlugin)


local DanmakuSourceSearchResult =
{
    isSplited               = classlite.declareConstantField(false),
    videoIDs                = classlite.declareTableField(),
    videoTitles             = classlite.declareTableField(),
    videoTitleColumnCount   = classlite.declareConstantField(1),
    preferredIDIndex        = classlite.declareConstantField(1),
}

classlite.declareClass(DanmakuSourceSearchResult)


return
{
    _HEADER_USER_AGENT                  = _HEADER_USER_AGENT,
    _HEADER_ACCEPT_XML                  = _HEADER_ACCEPT_XML,

    IDanmakuSourcePlugin                = IDanmakuSourcePlugin,
    _AbstractDanmakuSourcePlugin        = _AbstractDanmakuSourcePlugin,
    _PatternBasedDanmakuSourcePlugin    = _PatternBasedDanmakuSourcePlugin,
    DanmakuSourceSearchResult           = DanmakuSourceSearchResult,
}
----------------------- src/plugins/pluginbase.lua <END> -----------------------

            end
            requestedModule = src_plugins_pluginbase_lua()
            __loadedModules[path] = requestedModule
        end
        return requestedModule
    end
    if path == "src/plugins/srt"
    then
        local requestedModule = __loadedModules[path]
        if not requestedModule
        then
            local function src_plugins_srt_lua()


------------------------- src/plugins/srt.lua <START> --------------------------
local pluginbase    = require("src/plugins/pluginbase")
local types         = require("src/base/types")
local utils         = require("src/base/utils")
local constants     = require("src/base/constants")
local classlite     = require("src/base/classlite")
local danmaku       = require("src/core/danmaku")
local danmakupool   = require("src/core/danmakupool")


local _SRT_PLUGIN_NAME              = "SRT"
local _SRT_SUBTITLE_IDX_START       = 0
local _SRT_SEP_SUBTITLE             = constants.STR_EMPTY
local _SRT_PATTERN_STRIP_CR         = "^\r*(.-)\r*$"
local _SRT_PATTERN_SUBTITLE_IDX     = "^(%d+)$"
local _SRT_PATTERN_TIME             = "(%d+):(%d+):(%d+),(%d+)"
local _SRT_PATTERN_TIME_SPAN        = _SRT_PATTERN_TIME
                                      .. " %-%-%> "
                                      .. _SRT_PATTERN_TIME

local __readLine                    = nil
local __readSubtitleIdxOrEmptyLines = nil
local __readSubtitleTimeSpan        = nil
local __readSubtitleContent         = nil


__readLine = function(f)
    local line = f:read(constants.READ_MODE_LINE_NO_EOL)
    return line and line:match(_SRT_PATTERN_STRIP_CR)
end


__readSubtitleIdxOrEmptyLines = function(cfg, p, f, line, src, idx, offset, danmakuData)
    if not line
    then
        -- 允许以空行结尾，但不允许只有空行的文件
        return idx > _SRT_SUBTITLE_IDX_START
    end

    if line == _SRT_SEP_SUBTITLE
    then
        -- 继续读空行
        line = __readLine(f)
        return __readSubtitleIdxOrEmptyLines(cfg, p, f, line, src, idx, offset, danmakuData)
    else
        local nextIdx = line:match(_SRT_PATTERN_SUBTITLE_IDX)
        if not nextIdx
        then
            -- 没有起始的字幕编号
            return false
        else
            -- 某些字幕文件时间段不是递增的
            nextIdx = tonumber(nextIdx)
            line = __readLine(f)
            return __readSubtitleTimeSpan(cfg, p, f, line, src, nextIdx, offset, danmakuData)
        end
    end
end


__readSubtitleTimeSpan = function(cfg, p, f, line, src, idx, offset, danmakuData)
    local function __doConvert(h, m, s, ms)
        h = tonumber(h)
        m = tonumber(m)
        s = tonumber(s)
        ms = tonumber(ms)
        return utils.convertHHMMSSToTime(h, m, s, ms)
    end

    if not line
    then
        -- 只有字幕编号但没有时间段
        return false
    end

    local h1, m1, s1, ms1,
          h2, m2, s2, ms2 = line:match(_SRT_PATTERN_TIME_SPAN)

    if not h1
    then
        return false
    end

    local start = __doConvert(h1, m1, s1, ms1)
    local endTime = __doConvert(h2, m2, s2, ms2)
    local life = math.max(endTime - start, 0)
    line = __readLine(f)
    return __readSubtitleContent(cfg, p, f, line, src, idx, start, life, offset, danmakuData)
end


__readSubtitleContent = function(cfg, p, f, line, src, idx, start, life, offset, danmakuData)
    if not line
    then
        return false
    end

    local text = line
    local hasMoreLine = false
    while true
    do
        line = __readLine(f)
        hasMoreLine = types.isString(line)
        if not line or line == _SRT_SEP_SUBTITLE
        then
            break
        end

        -- 有些字幕会换行
        text = text .. constants.STR_NEWLINE .. line
    end

    danmakuData.startTime = start + offset
    danmakuData.lifeTime = life
    danmakuData.fontColor = cfg.subtitleFontColor
    danmakuData.fontSize = cfg.subtitleFontSize
    danmakuData.sourceID = src
    danmakuData.danmakuID = tonumber(idx)
    danmakuData.danmakuText = text
    p:addDanmaku(danmakuData)

    line = hasMoreLine and __readLine(f)
    return __readSubtitleIdxOrEmptyLines(cfg, p, f, line, src, idx, offset, danmakuData)
end


local function _parseSRTFile(cfg, pool, file, srcID, offset, danmakuData)
    local line = __readLine(file)
    local idx = _SRT_SUBTITLE_IDX_START
    return __readSubtitleIdxOrEmptyLines(cfg, pool, file, line, srcID, idx, offset, danmakuData)
end


local SRTDanmakuSourcePlugin =
{
    _mDanmakuData   = classlite.declareClassField(danmaku.DanmakuData),


    getName = function(self)
        return _SRT_PLUGIN_NAME
    end,

    parseFile = function(self, filePath, sourceID, timeOffset)
        local app = self._mApplication
        local file = app:readUTF8File(filePath)
        if types.isOpenedFile(file)
        then
            local cfg = app:getConfiguration()
            local pools = app:getDanmakuPools()
            local pool = pools:getDanmakuPoolByLayer(danmakupool.LAYER_SUBTITLE)
            local danmakuData = self._mDanmakuData
            _parseSRTFile(cfg, pool, file, sourceID, timeOffset, danmakuData)
            app:closeFile(file)
        end
    end,
}

classlite.declareClass(SRTDanmakuSourcePlugin, pluginbase.IDanmakuSourcePlugin)


return
{
    _parseSRTFile           = _parseSRTFile,
    SRTDanmakuSourcePlugin  = SRTDanmakuSourcePlugin,
}
-------------------------- src/plugins/srt.lua <END> ---------------------------

            end
            requestedModule = src_plugins_srt_lua()
            __loadedModules[path] = requestedModule
        end
        return requestedModule
    end
    if path == "src/shell/application"
    then
        local requestedModule = __loadedModules[path]
        if not requestedModule
        then
            local function src_shell_application_lua()


---------------------- src/shell/application.lua <START> -----------------------
local types         = require("src/base/types")
local utils         = require("src/base/utils")
local constants     = require("src/base/constants")
local classlite     = require("src/base/classlite")
local unportable    = require("src/base/unportable")
local danmakupool   = require("src/core/danmakupool")
local pluginbase    = require("src/plugins/pluginbase")
local srt           = require("src/plugins/srt")
local acfun         = require("src/plugins/acfun")
local bilibili      = require("src/plugins/bilibili")
local dandanplay    = require("src/plugins/dandanplay")


local _APP_MD5_BYTE_COUNT       = 32 * 1024 * 1024
local _APP_PRIVATE_DIR_NAME     = ".mpvdanmakuloader"
local _APP_CFG_FILE_NAME        = "cfg.lua"
local _APP_ASS_FILE_SUFFIX      = ".ass"

local _TAG_LOG_WIDTH            = 14
local _TAG_PLUGIN               = "plugin"
local _TAG_NETWORK              = "network"
local _TAG_FILESYSTEM           = "filesystem"
local _TAG_SUBTITLE             = "subtitle"


local _MPV_CMD_ADD_SUBTITLE             = "sub-add"
local _MPV_CMD_DELETE_SUBTITLE          = "sub-remove"
local _MPV_PROP_MAIN_SUBTITLE_ID        = "sid"
local _MPV_PROP_SECONDARY_SUBTITLE_ID   = "secondary-sid"
local _MPV_PROP_TRACK_COUNT             = "track-list/count"
local _MPV_PROP_TRACK_ID                = "track-list/%d/id"
local _MPV_ARG_READDIR_ONLY_FILES       = "files"
local _MPV_ARG_READDIR_ONLY_DIRS        = "dirs"
local _MPV_ARG_ADDSUB_AUTO              = "auto"
local _MPV_CONST_NO_SUBTITLE_ID         = "no"
local _MPV_CONST_MEMORY_FILE_PREFFIX    = "memory://"


local MPVDanmakuLoaderApp =
{
    _mConfiguration                     = classlite.declareTableField(),
    _mDanmakuPools                      = classlite.declareClassField(danmakupool.DanmakuPools),
    _mNetworkConnection                 = classlite.declareClassField(unportable.CURLNetworkConnection),
    _mDanmakuSourcePlugins              = classlite.declareTableField(),
    _mUniquePathGenerator               = classlite.declareClassField(unportable.UniquePathGenerator),
    _mLogFunction                       = classlite.declareConstantField(nil),

    __mVideoFileMD5                     = classlite.declareConstantField(nil),
    __mVideoFilePath                    = classlite.declareConstantField(nil),
    __mPrivateDirPath                   = classlite.declareConstantField(nil),
    __mAddedMemorySubtitleID            = classlite.declareConstantField(nil),


    new = function(self)
        -- 在这些统一做 monkey patch 可以省一些的重复代码，例如文件操作那堆 Log
        self:_initDanmakuSourcePlugins()
        self:__attachMethodLoggingHooks()
    end,

    __attachMethodLoggingHooks = function(self)
        local function __patchFunction(orgFunc, patchFunc)
            local ret = function(...)
                utils.invokeSafely(patchFunc, ...)
                return utils.invokeSafely(orgFunc, ...)
            end
            return ret
        end

        local function __createPatchedFSFunction(orgFunc, subTag)
            local ret = function(self, arg1, ...)
                local ret = orgFunc(self, arg1, ...)
                local arg1Str = arg1 or constants.STR_EMPTY
                arg1Str = types.isString(arg1) and string.format("%q", arg1Str) or arg1Str
                self:_printLog(_TAG_FILESYSTEM, "%s(%s) -> %s", subTag, arg1Str, tostring(ret))
                return ret
            end
            return ret
        end

        local clzApp = self:getClass()
        self.readFile       = __createPatchedFSFunction(clzApp.readFile,        "read")
        self.readUTF8File   = __createPatchedFSFunction(clzApp.readUTF8File,    "readUTF8")
        self.writeFile      = __createPatchedFSFunction(clzApp.writeFile,       "writeFile")
        self.closeFile      = __createPatchedFSFunction(clzApp.closeFile,       "closeFile")
        self.createDir      = __createPatchedFSFunction(clzApp.createDir,       "createDir")
        self.deleteTree     = __createPatchedFSFunction(clzApp.deleteTree,      "deleteTree")
        self.createTempFile = __createPatchedFSFunction(clzApp.createTempFile,  "createTempFile")

        local function __printNetworkLog(_, url)
            self:_printLog(_TAG_NETWORK, "GET %s", url)
        end
        local conn = self._mNetworkConnection
        conn._createConnection = __patchFunction(conn:getClass()._createConnection, __printNetworkLog)

        local function __printSubtitleFilePath(_, path)
            self:_printLog(_TAG_SUBTITLE, "file: %s", path)
        end
        self.setSubtitleFile = __patchFunction(clzApp.setSubtitleFile, __printSubtitleFilePath)

        local function __printSubtitleData(_, data)
            self:_printLog(_TAG_SUBTITLE, "data")
        end
        self.setSubtitleData = __patchFunction(clzApp.setSubtitleData, __printSubtitleData)

        for _, plugin in self:iterateDanmakuSourcePlugins()
        do
            local orgSearchFunc = plugin:getClass().search
            plugin.search = function(plugin, keyword, ...)
                local ret = orgSearchFunc(plugin, keyword, ...)
                if ret
                then
                    self:_printLog(_TAG_PLUGIN, "search(%q) -> %s", keyword, plugin:getName())
                end
                return ret
            end
        end
    end,


    setLogFunction = function(self, func)
        self._mLogFunction = types.isFunction(func) and func
    end,

    _printLog = function(self, tag, fmt, ...)
        local func = self._mLogFunction
        if not func
        then
            return
        end

        local wordWidth = #tag
        local maxWidth = _TAG_LOG_WIDTH
        local leadingSpaceCount = math.floor((maxWidth - wordWidth) / 2)
        local trailingSpaceCount = math.max(maxWidth - wordWidth - leadingSpaceCount, 0)
        local leadingSpaces = string.rep(constants.STR_SPACE, leadingSpaceCount)
        local trailingSpaces = string.rep(constants.STR_SPACE, trailingSpaceCount)
        func(string.format("[%s%s%s]  " .. fmt, leadingSpaces, tag, trailingSpaces, ...))
    end,

    init = function(self, filePath)
        local dir = filePath and unportable.splitPath(filePath)
        self.__mPrivateDirPath = dir and unportable.joinPath(dir, _APP_PRIVATE_DIR_NAME)
        self.__mVideoFileMD5 = nil
        self.__mVideoFilePath = filePath
        self.__mAddedMemorySubtitleID = nil
        self._mNetworkConnection:reset()
        self._mDanmakuPools:clear()
    end,


    updateConfiguration = function(self)
        local cfg = self._mConfiguration
        self:_initConfiguration(cfg)
        self:_updateConfiguration(cfg)

        local pools = self._mDanmakuPools
        for _, pool in pools:iteratePools()
        do
            pool:setModifyDanmakuDataHook(cfg.modifyDanmakuDataHook)
        end
        pools:setCompareSourceIDHook(cfg.modifySourceIDHook)
        self._mNetworkConnection:setTimeout(cfg.networkTimeout)
    end,

    _initConfiguration = function(self, cfg)
        utils.clearTable(cfg)

        -- 弹幕属性
        cfg.danmakuFontSize                 = 34                -- 弹幕默认字体大小
        cfg.danmakuFontName                 = "sans-serif"      -- 弹幕默认字体名
        cfg.danmakuFontColor                = 0xFFFFFF          -- 弹幕默认颜色 RRGGBB
        cfg.subtitleFontSize                = 34                -- 字幕默认字体大小
        cfg.subtitleFontName                = "mono"            -- 字幕默认字体名
        cfg.subtitleFontColor               = 0xFFFFFF          -- 字幕默认颜色 RRGGBB
        cfg.movingDanmakuLifeTime           = 8000              -- 滚动弹幕存活时间
        cfg.staticDanmakuLIfeTime           = 5000              -- 固定位置弹幕存活时间
        cfg.danmakuResolutionX              = 1280              -- 弹幕分辨率
        cfg.danmakuResolutionY              = 720
        cfg.danmakuReservedBottomHeight     = 30                -- 弹幕底部预留空间
        cfg.subtitleReservedBottomHeight    = 10                -- 字幕底部预留空间

        -- 钩子函数
        cfg.modifyDanmakuDataHook           = nil               -- 修改或过滤此弹幕
        cfg.modifyDanmakuStyleHook          = nil               -- 修改弹幕样式
        cfg.modifySubtitleStyleHook         = nil               -- 作用同上，不过只作用于字幕
        cfg.compareSourceIDHook             = nil               -- 判断弹幕来源是否相同

        -- 路径相关
        cfg.trashDirPath                    = nil               -- 如果不为空，所有删除都替换成移动，前提是目录存在
        cfg.rawDataRelDirPath               = "rawdata"         -- 下载到本地的弹幕源原始数据目录
        cfg.metaDataRelFilePath             = "sourcemeta.lua"  -- 记录弹幕源的原始信息

        -- 设置
        cfg.showDebugLog                    = true              -- 是否输出调试信息
        cfg.pauseWhileShowing               = true              -- 弹窗后是否暂停播放
        cfg.saveGeneratedASS                = false             -- 是否保存每次生成的弹幕文件
        cfg.networkTimeout                  = nil               -- 网络请求超时秒数
        cfg.promptReplaceMainSubtitle       = true              -- 是否提示替换当前弹幕
    end,

    _updateConfiguration = function(self, cfg)
        local cfgFilePath = unportable.joinPath(self:_getPrivateDirPath(), _APP_CFG_FILE_NAME)
        if self:isExistedFile(cfgFilePath)
        then
            local func = loadfile(cfgFilePath, constants.LOAD_MODE_CHUNKS, _ENV)
            pcall(func, cfg)
        end
    end,

    getPluginByName = function(self, name)
        for _, plugin in self:iterateDanmakuSourcePlugins()
        do
            if plugin:getName() == name
            then
                return plugin
            end
        end
    end,

    _addDanmakuSourcePlugin = function(self, plugin)
        if classlite.isInstanceOf(plugin, pluginbase.IDanmakuSourcePlugin)
            and not self:getPluginByName(plugin:getName())
        then
            table.insert(self._mDanmakuSourcePlugins, plugin)
            plugin:setApplication(self)
        end
    end,

    _initDanmakuSourcePlugins = function(self)
        local plugins = utils.clearTable(self._mDanmakuSourcePlugins)
        self:_addDanmakuSourcePlugin(srt.SRTDanmakuSourcePlugin:new())
        self:_addDanmakuSourcePlugin(acfun.AcfunDanmakuSourcePlugin:new())
        self:_addDanmakuSourcePlugin(bilibili.BiliBiliDanmakuSourcePlugin:new())
        self:_addDanmakuSourcePlugin(dandanplay.DanDanPlayDanmakuSourcePlugin:new())
    end,

    iterateDanmakuSourcePlugins = function(self)
        return utils.iterateArray(self._mDanmakuSourcePlugins)
    end,

    getConfiguration = function(self)
        return self._mConfiguration
    end,

    getDanmakuPools = function(self)
        return self._mDanmakuPools
    end,

    getNetworkConnection = function(self)
        return self._mNetworkConnection
    end,

    __doAddSubtitle = function(self, arg)
        local orgSID = mp.get_property(_MPV_PROP_MAIN_SUBTITLE_ID)
        local orgTrackCount = mp.get_property_number(_MPV_PROP_TRACK_COUNT, 0)
        mp.commandv(_MPV_CMD_ADD_SUBTITLE, arg)
        mp.set_property(_MPV_PROP_MAIN_SUBTITLE_ID, orgSID)

        local newTrackCount = mp.get_property_number(_MPV_PROP_TRACK_COUNT, 1)
        if newTrackCount > orgTrackCount
        then
            local prop = string.format(_MPV_PROP_TRACK_ID, newTrackCount - 1)
            return mp.get_property(prop)
        end
    end,

    addSubtitleFile = function(self, path)
        if self:isExistedFile(path)
        then
            return self:__doAddSubtitle(path)
        end
    end,

    addSubtitleData = function(self, data)
        local function __unsetSID(propName, sid)
            if mp.get_property(propName) == sid
            then
                mp.set_property(propName, _MPV_CONST_NO_SUBTITLE_ID)
            end
        end

        if types.isNilOrEmpty(data)
        then
            return
        end

        local newSID = self:__doAddSubtitle(_MPV_CONST_MEMORY_FILE_PREFFIX .. data)
        if newSID
        then
            -- 只保留一个内存字幕
            local memorySID = self.__mAddedMemorySubtitleID
            if memorySID
            then
                __unsetSID(_MPV_PROP_MAIN_SUBTITLE_ID, memorySID)
                __unsetSID(_MPV_PROP_SECONDARY_SUBTITLE_ID, memorySID)
                mp.commandv(_MPV_CMD_DELETE_SUBTITLE, memorySID)
            end

            self.__mAddedMemorySubtitleID = newSID
            return newSID
        end
    end,

    setMainSubtitleByID = function(self, sid)
        if types.isString(sid)
        then
            mp.set_property(_MPV_PROP_MAIN_SUBTITLE_ID, sid)
        end
    end,

    setSecondarySubtitleByID = function(self, sid)
        if types.isString(sid)
        then
            mp.set_property(_MPV_PROP_SECONDARY_SUBTITLE_ID, sid)
        end
    end,

    getMainSubtitleID = function(self)
        local sid = mp.get_property(_MPV_PROP_MAIN_SUBTITLE_ID)
        return sid ~= _MPV_CONST_NO_SUBTITLE_ID and sid
    end,

    listFiles = function(self, dir, outList)
        local files = mp.utils.readdir(dir, _MPV_ARG_READDIR_ONLY_FILES)
        utils.clearTable(outList)
        utils.appendArrayElements(outList, files)
    end,

    createDir = function(self, dir)
        return types.isString(dir) and unportable.createDir(dir)
    end,

    deleteTree = function(self, fullPath)
        if types.isString(fullPath)
        then
            local trashDirPath = self._mConfiguration.trashDirPath
            return types.isString(trashDirPath)
                and unportable.moveTree(fullPath, trashDirPath, true)
                or unportable.deleteTree(fullPath)
        end
    end,

    createTempFile = function(self)
        return io.tmpfile()
    end,

    readFile = function(self, fullPath)
        return types.isString(fullPath) and io.read(fullPath)
    end,

    readUTF8File = function(self, fullPath)
        return types.isString(fullPath) and unportable.readUTF8File(fullPath)
    end,

    writeFile = function(self, fullPath, mode)
        mode = mode or constants.FILE_MODE_WRITE_ERASE
        return types.isString(fullPath) and io.open(fullPath, mode)
    end,

    closeFile = function(self, file)
        utils.closeSafely(file)
    end,

    isExistedDir = function(self, fullPath)
        local ret = false
        if types.isString(fullPath)
        then
            local parentDir, dir = unportable.splitPath(fullPath)
            local dirs = mp.utils.readdir(parentDir, _MPV_ARG_READDIR_ONLY_DIRS)
            ret = utils.linearSearchArray(dirs, dir)
        end
        return ret
    end,

    isExistedFile = function(self, fullPath)
        local file = nil
        if types.isString(fullPath)
        then
            file = io.open(fullPath)
            utils.closeSafely(file)
        end
        return types.toBoolean(file)
    end,

    getUniqueFilePath = function(self, dir, prefix, suffix)
        local function __isExistedPath(app, fullPath)
            return app:isExistedFile(fullPath) or app:isExistedDir(fullPath)
        end

        local generator = self._mUniquePathGenerator
        return generator:getUniquePath(dir, prefix, suffix, __isExistedPath, self)
    end,

    getVideoFileMD5 = function(self)
        local md5 = self.__mVideoFileMD5
        if md5
        then
            return md5
        end

        local fullPath = self.__mVideoFilePath
        md5 = fullPath and unportable.calcFileMD5(fullPath, _APP_MD5_BYTE_COUNT)
        self.__mVideoFileMD5 = md5
        return md5
    end,

    _getPrivateDirPath = function(self)
        return self.__mPrivateDirPath
    end,

    __doGetConfigurationFullPath = function(self, relPath)
        local dir = self:_getPrivateDirPath()
        return dir and relPath and unportable.joinPath(dir, relPath)
    end,

    getDanmakuSourceRawDataDirPath = function(self)
        local cfg = self:getConfiguration()
        return cfg and self:__doGetConfigurationFullPath(cfg.rawDataRelDirPath)
    end,

    getDanmakuSourceMetaDataFilePath = function(self)
        local cfg = self:getConfiguration()
        return cfg and self:__doGetConfigurationFullPath(cfg.metaDataRelFilePath)
    end,

    getGeneratedASSFilePath = function(self)
        if self:getConfiguration().saveGeneratedASS
        then
            local videoFilePath = self.__mVideoFilePath
            return videoFilePath and videoFilePath .. _APP_ASS_FILE_SUFFIX
        end
    end,

    getCurrentDateTime = function(self)
        return os.time()
    end,
}

classlite.declareClass(MPVDanmakuLoaderApp)


return
{
    MPVDanmakuLoaderApp         = MPVDanmakuLoaderApp,
}
----------------------- src/shell/application.lua <END> ------------------------

            end
            requestedModule = src_shell_application_lua()
            __loadedModules[path] = requestedModule
        end
        return requestedModule
    end
    if path == "src/shell/logic"
    then
        local requestedModule = __loadedModules[path]
        if not requestedModule
        then
            local function src_shell_logic_lua()


------------------------- src/shell/logic.lua <START> --------------------------
local utils         = require("src/base/utils")
local types         = require("src/base/types")
local constants     = require("src/base/constants")
local classlite     = require("src/base/classlite")
local unportable    = require("src/base/unportable")
local pluginbase    = require("src/plugins/pluginbase")
local application   = require("src/shell/application")
local uiconstants   = require("src/shell/uiconstants")
local sourcemgr     = require("src/shell/sourcemgr")


local _SHELL_TIMEOFFSET_START       = 0
local _SHELL_DESCRIPTION_VID_SEP    = ","


local MPVDanmakuLoaderShell =
{
    _mApplication               = classlite.declareConstantField(nil),
    _mDanmakuSourceManager      = classlite.declareClassField(sourcemgr.DanmakuSourceManager),

    _mUIStrings                 = classlite.declareConstantField(uiconstants.UI_STRINGS_CN),
    _mUISizes                   = classlite.declareConstantField(uiconstants.UI_SIZES_ZENITY),

    _mGUIBuilder                = classlite.declareClassField(unportable.ZenityGUIBuilder),
    __mTextInfoProperties       = classlite.declareClassField(unportable.TextInfoProperties),
    __mListBoxProperties        = classlite.declareClassField(unportable.ListBoxProperties),
    __mEntryProperties          = classlite.declareClassField(unportable.EntryProperties),
    __mFileSelectionProperties  = classlite.declareClassField(unportable.FileSelectionProperties),
    __mProgressBarProperties    = classlite.declareClassField(unportable.ProgressBarProperties),
    __mQuestionProperties       = classlite.declareClassField(unportable.QuestionProperties),

    _mDanmakuSources            = classlite.declareTableField(),

    __mSelectedIndexes          = classlite.declareTableField(),
    __mSelectedFilePaths        = classlite.declareTableField(),
    __mOptionStrings            = classlite.declareTableField(),

    __mVideoIDs                 = classlite.declareTableField(),
    __mStartTimeOffsets         = classlite.declareTableField(),
    __mDanmakuRawDatas          = classlite.declareTableField(),
    __mToBeUpdatedSources       = classlite.declareTableField(),
    __mPlugins                  = classlite.declareTableField(),

    __mSearchResult             = classlite.declareClassField(pluginbase.DanmakuSourceSearchResult),


    dispose = function(self)
        utils.forEachArrayElement(self._mDanmakuSources, utils.disposeSafely)
    end,

    setApplication = function(self, app)
        local sourceMgr = self._mDanmakuSourceManager
        self._mApplication = app
        app:getDanmakuPools():clear()
        sourceMgr:setApplication(app)
        sourceMgr:recycleDanmakuSources(self._mDanmakuSources)
    end,

    __showSelectPlugins = function(self)
        local plugins = utils.clearTable(self.__mPlugins)
        local props = self.__mListBoxProperties
        props:reset()
        self:__initWindowProperties(props, self._mUISizes.select_plugin)
        props.listBoxTitle = self._mUIStrings.title_select_plugin
        props.listBoxColumnCount = 1
        props.isHeaderHidden = true
        for _, plugin in self._mApplication:iterateDanmakuSourcePlugins()
        do
            table.insert(plugins, plugin)
            table.insert(props.listBoxElements, plugin:getName())
        end

        local selectedIndexes = utils.clearTable(self.__mSelectedIndexes)
        if self._mGUIBuilder:showListBox(props, selectedIndexes)
        then
            return plugins[selectedIndexes[1]]
        end
    end,

    __showSelectFiles = function(self, outPaths)
        local props = self.__mFileSelectionProperties
        props:reset()
        self:__initWindowProperties(props)
        props.isMultiSelectable = true
        return self._mGUIBuilder:showFileSelection(props, outPaths)
    end,

    _showAddLocalDanmakuSource = function(self)
        local paths = utils.clearTable(self.__mSelectedFilePaths)
        local plugin = self:__showSelectPlugins()
        local hasSelectedFile = plugin and self:__showSelectFiles(paths)
        if hasSelectedFile
        then
            local sources = self._mDanmakuSources
            local sourceMgr = self._mDanmakuSourceManager
            for _, path in ipairs(paths)
            do
                sourceMgr:addLocalDanmakuSource(sources, plugin, path)
            end
        end

        return self:_showMain()
    end,


    _showSearchDanmakuSource = function(self)
        local props = self.__mEntryProperties
        props:reset()
        self:__initWindowProperties(props)
        props.entryTitle = self._mUIStrings.title_search_danmaku_source

        local input = self._mGUIBuilder:showEntry(props)
        if types.isNilOrEmpty(input)
        then
            return self:_showMain()
        end

        local result = self.__mSearchResult
        for _, plugin in self._mApplication:iterateDanmakuSourcePlugins()
        do
            result:reset()
            if plugin:search(input, result)
            then
                return self:__showSelectNewDanmakuSource(plugin, result)
            end
        end

        -- 即使没有搜索结果也要弹一下
        result:reset()
        return self:__showSelectNewDanmakuSource(nil, result)
    end,


    __showSelectNewDanmakuSource = function(self, plugin, result)
        local function __initListBoxHeaders(props, headerFormat, colCount)
            props.listBoxColumnCount = colCount
            for i = 1, colCount
            do
                local header = string.format(headerFormat, i)
                table.insert(props.listBoxHeaders, header)
            end
        end

        local function __getDanmakuTimeOffsets(plugin, videoIDs, timeOffsets)
            -- 最后一个分集视频的时长不需要知道
            local lastVID = utils.popArrayElement(videoIDs)
            if not types.isEmptyTable(videoIDs)
            then
                plugin:getVideoDurations(videoIDs, timeOffsets)
            end
            table.insert(timeOffsets, 1, _SHELL_TIMEOFFSET_START)
            table.insert(videoIDs, lastVID)
        end

        local uiStrings = self._mUIStrings
        local props = self.__mListBoxProperties
        props:reset()
        self:__initWindowProperties(props, self._mUISizes.select_new_danmaku_source)
        props.listBoxTitle = uiStrings.title_select_new_danmaku_source
        props.isMultiSelectable = result.isSplited
        utils.appendArrayElements(props.listBoxElements, result.videoTitles)
        __initListBoxHeaders(props,
                             uiStrings.fmt_select_new_danmaku_source_header,
                             result.videoTitleColumnCount)

        local selectedIndexes = utils.clearTable(self.__mSelectedIndexes)
        if not self._mGUIBuilder:showListBox(props, selectedIndexes)
        then
            return self:_showSearchDanmakuSource()
        end

        local videoIDs = utils.clearTable(self.__mVideoIDs)
        for _, idx in utils.iterateArray(selectedIndexes)
        do
            table.insert(videoIDs, result.videoIDs[idx])
        end

        local desc = table.concat(videoIDs, _SHELL_DESCRIPTION_VID_SEP)
        local offsets = utils.clearTable(self.__mStartTimeOffsets)
        __getDanmakuTimeOffsets(plugin, videoIDs, offsets)

        local sources = self._mDanmakuSources
        local sourceMgr = self._mDanmakuSourceManager
        local source = sourceMgr:addCachedDanmakuSource(sources, plugin, desc, videoIDs, offsets)

        return self:_showMain()
    end,


    __doShowDanmakuSources = function(self, title, iterFunc, selectedJumpFunc, noselectedJumpFunc)
        local props = self.__mListBoxProperties
        props:reset()
        self:__initWindowProperties(props, self._mUISizes.show_danmaku_sources)
        props.listBoxTitle = title
        props.isMultiSelectable = true

        local uiStrings = self._mUIStrings
        table.insert(props.listBoxHeaders, uiStrings.column_sources_date)
        table.insert(props.listBoxHeaders, uiStrings.column_sources_plugin_name)
        table.insert(props.listBoxHeaders, uiStrings.column_sources_description)
        props.listBoxColumnCount = #props.listBoxHeaders

        local sources = self._mDanmakuSources
        local datetimeFormat = uiStrings.fmt_danmaku_source_datetime
        local unknownDatetimeString = uiStrings.datetime_unknown
        for _, source in utils.iterateArray(sources)
        do
            local date = source:getDate()
            local dateString = date and os.date(datetimeFormat, date) or unknownDatetimeString
            table.insert(props.listBoxElements, dateString)
            table.insert(props.listBoxElements, source:getPluginName())
            table.insert(props.listBoxElements, source:getDescription())
        end

        local selectedIndexes = utils.clearTable(self.__mSelectedIndexes)
        if self._mGUIBuilder:showListBox(props, selectedIndexes)
        then
            table.sort(selectedIndexes)
            for _, idx in utils.reverseIterateArray(selectedIndexes)
            do
                iterFunc(self, sources, idx)
            end
            return selectedJumpFunc(self)
        else
            return noselectedJumpFunc(self)
        end
    end,


    __doCommitDanmakus = function(self, assFilePath)
        local sid = nil
        local app = self._mApplication
        local pools = app:getDanmakuPools()
        if assFilePath
        then
            app:deleteTree(assFilePath)

            local file = app:writeFile(assFilePath, constants.FILE_MODE_WRITE_ERASE)
            local hasContent = pools:writeDanmakus(app, file)
            pools:clear()
            app:closeFile(file)
            if hasContent
            then
                sid = app:addSubtitleFile(assFilePath)
            end
        else
            local file = app:createTempFile()
            local hasContent = pools:writeDanmakus(app, file)
            pools:clear()
            file:seek(constants.SEEK_MODE_BEGIN)
            if hasContent
            then
                sid = app:addSubtitleData(file:read(constants.READ_MODE_ALL))
            end
            app:closeFile(file)
        end

        if not sid
        then
            return
        end

        local shouldReplace = false
        local mainSID = app:getMainSubtitleID()
        if not app:getConfiguration().promptReplaceMainSubtitle and mainSID
        then
            local uiStrings = self._mUIStrings
            local questionProps = self.__mQuestionProperties
            questionProps:reset()
            self:__initWindowProperties(questionProps)
            questionProps.questionText = uiStrings.select_subtitle_should_replace
            questionProps.labelTextOK = uiStrings.select_subtitle_ok
            questionProps.labelTextCancel = uiStrings.select_subtitle_cancel
            shouldReplace = self._mGUIBuilder:showQuestion(questionProps)
        end

        app:setMainSubtitleByID(sid)
        app:setSecondarySubtitleByID(shouldReplace and mainSID)
    end,

    __commitDanmakus = function(self)
        local assFilePath = self._mApplication:getGeneratedASSFilePath()
        self:__doCommitDanmakus(assFilePath)
    end,

    _showGenerateASSFile = function(self)
        local function __parseSource(self, sources, idx)
            sources[idx]:parse(self._mApplication)
        end

        self._mApplication:getDanmakuPools():clear()
        return self:__doShowDanmakuSources(self._mUIStrings.title_generate_ass_file,
                                           __parseSource,
                                           self.__commitDanmakus,
                                           self._showMain)
    end,


    _showDeleteDanmakuSource = function(self)
        local function __deleteSource(self, sources, idx)
            if self._mDanmakuSourceManager:deleteDanmakuSourceByIndex(sources, idx)
            then
                table.remove(sources, idx)
            end
        end

        return self:__doShowDanmakuSources(self._mUIStrings.title_delete_danmaku_source,
                                           __deleteSource,
                                           self._showDeleteDanmakuSource,
                                           self._showMain)
    end,


    _showUpdateDanmakuSource = function(self)
        local function __updateSource(self, sources, idx)
            table.insert(self.__mToBeUpdatedSources, sources[idx])
        end

        local function __updateAndShowDanmakuSources(self)
            local toBeUpdatedSources = self.__mToBeUpdatedSources
            local sourceMgr = self._mDanmakuSourceManager
            sourceMgr:updateDanmakuSources(toBeUpdatedSources, self._mDanmakuSources)
            utils.clearTable(toBeUpdatedSources)
            return self:_showUpdateDanmakuSource()
        end

        utils.clearTable(self.__mToBeUpdatedSources)
        return self:__doShowDanmakuSources(self._mUIStrings.title_update_danmaku_source,
                                           __updateSource,
                                           __updateAndShowDanmakuSources,
                                           self._showMain)
    end,


    __initWindowProperties = function(self, props, sizeSpec)
        props.windowTitle = self._mUIStrings.title_app
        props.windowWidth = sizeSpec and sizeSpec[1]
        props.windowHeight = sizeSpec and sizeSpec[2]
    end,


    _showMain = function(self)
        local uiStrings = self._mUIStrings
        local props = self.__mListBoxProperties
        props:reset()
        self:__initWindowProperties(props, self._mUISizes.main)
        props.listBoxTitle = uiStrings.title_main
        props.listBoxColumnCount = 1
        props.isHeaderHidden = true

        local options = utils.clearTable(self.__mOptionStrings)
        table.insert(options, uiStrings.option_main_add_local_danmaku_source)
        table.insert(options, uiStrings.option_main_search_danmaku_source)
        table.insert(options, uiStrings.option_main_update_danmaku_source)
        table.insert(options, uiStrings.option_main_delete_danmaku_source)
        table.insert(options, uiStrings.option_main_generate_ass_file)
        utils.appendArrayElements(props.listBoxElements, options)

        local selectedIndexes = self.__mSelectedIndexes
        self._mGUIBuilder:showListBox(props, selectedIndexes)

        local idx = selectedIndexes[1]
        local optionString = idx and options[idx]
        if optionString == uiStrings.option_main_add_local_danmaku_source
        then
            return self:_showAddLocalDanmakuSource()
        elseif optionString == uiStrings.option_main_search_danmaku_source
        then
            return self:_showSearchDanmakuSource()
        elseif optionString == uiStrings.option_main_update_danmaku_source
        then
            return self:_showUpdateDanmakuSource()
        elseif optionString == uiStrings.option_main_generate_ass_file
        then
            return self:_showGenerateASSFile()
        elseif optionString == uiStrings.option_main_delete_danmaku_source
        then
            return self:_showDeleteDanmakuSource()
        end
    end,


    showMainWindow = function(self)
        self._mDanmakuSourceManager:listDanmakuSources(self._mDanmakuSources)
        return self:_showMain()
    end,


    loadDanmakuFromURL = function(self, url)
        local uiStrings = self._mUIStrings
        local guiBuilder = self._mGUIBuilder
        local progressBarProps = self.__mProgressBarProperties
        progressBarProps:reset()
        self:__initWindowProperties(progressBarProps)

        local succeed = false
        local result = self.__mSearchResult
        local app = self._mApplication
        local handler = guiBuilder:showProgressBar(progressBarProps)
        guiBuilder:advanceProgressBar(handler, 10, uiStrings.load_progress_search)
        for _, plugin in app:iterateDanmakuSourcePlugins()
        do
            if plugin:search(url, result)
            then
                local ids = utils.clearTable(self.__mVideoIDs)
                local rawDatas = utils.clearTable(self.__mDanmakuRawDatas)
                local videoID = result.videoIDs[result.preferredIDIndex]
                table.insert(ids, videoID)

                guiBuilder:advanceProgressBar(handler, 60, uiStrings.load_progress_download)
                plugin:downloadDanmakuRawDatas(ids, rawDatas)

                local data = rawDatas[1]
                if types.isString(data)
                then
                    local offset = _SHELL_TIMEOFFSET_START
                    local pluginName = plugin:getName()
                    local pools = app:getDanmakuPools()
                    local sourceID = pools:allocateDanmakuSourceID(pluginName, videoID, nil, offset)
                    guiBuilder:advanceProgressBar(handler, 90, uiStrings.load_progress_parse)
                    plugin:parseData(data, sourceID, offset)
                    self:__doCommitDanmakus()
                    succeed = true
                end
            end
        end

        local lastMsg = succeed and uiStrings.load_progress_succeed or uiStrings.load_progress_failed
        guiBuilder:advanceProgressBar(handler, 100, lastMsg)
        guiBuilder:finishProgressBar(handler)
    end,
}

classlite.declareClass(MPVDanmakuLoaderShell)


return
{
    MPVDanmakuLoaderShell   = MPVDanmakuLoaderShell,
}

-------------------------- src/shell/logic.lua <END> ---------------------------

            end
            requestedModule = src_shell_logic_lua()
            __loadedModules[path] = requestedModule
        end
        return requestedModule
    end
    if path == "src/shell/sourcemgr"
    then
        local requestedModule = __loadedModules[path]
        if not requestedModule
        then
            local function src_shell_sourcemgr_lua()


----------------------- src/shell/sourcemgr.lua <START> ------------------------
local types         = require("src/base/types")
local utils         = require("src/base/utils")
local constants     = require("src/base/constants")
local classlite     = require("src/base/classlite")
local serialize     = require("src/base/serialize")
local unportable    = require("src/base/unportable")
local pluginbase    = require("src/plugins/pluginbase")
local application   = require("src/shell/application")


local _RAW_DATA_FILE_PREFIX         = "raw_"
local _RAW_DATA_FILE_FMT_SUFFIX     = "_%d.txt"

local _DEFAULT_START_TIME_OFFSET    = 0


local function __deleteDownloadedFiles(app, filePaths)
    local function __deleteFile(fullPath, _, __, app)
        app:deleteTree(fullPath)
    end
    utils.forEachArrayElement(filePaths, __deleteFile, app)
    utils.clearTable(filePaths)
end


local function __downloadDanmakuRawDataFiles(app, plugin, videoIDs, outFilePaths)
    if not classlite.isInstanceOf(app, application.MPVDanmakuLoaderApp)
        or types.isNilOrEmpty(videoIDs)
        or not types.isTable(outFilePaths)
    then
        return false
    end

    local function __writeRawData(content, rawDatas)
        table.insert(rawDatas, content)
    end

    -- 没有指定缓存的文件夹
    local baseDir = app:getDanmakuSourceRawDataDirPath()
    if not baseDir
    then
        return false
    end

    -- 创建文件夹失败
    local hasCreatedDir = app:isExistedDir(baseDir)
    hasCreatedDir = hasCreatedDir or app:createDir(baseDir)
    if not hasCreatedDir
    then
        return false
    end

    -- 先用此数组来暂存下载内容，下载完写文件后再转为路径
    local rawDatas = utils.clearTable(outFilePaths)
    plugin:downloadDanmakuRawDatas(videoIDs, rawDatas)

    -- 有文件下不动的时候，数量就对不上
    if not hasCreatedDir or #rawDatas ~= #videoIDs
    then
        utils.clearTable(rawDatas)
        return false
    end

    for i, rawData in utils.iterateArray(rawDatas)
    do
        local suffix = string.format(_RAW_DATA_FILE_FMT_SUFFIX, i)
        local fullPath = app:getUniqueFilePath(baseDir, _RAW_DATA_FILE_PREFIX, suffix)
        local f = app:writeFile(fullPath)
        if not utils.writeAndCloseFile(f, rawData)
        then
            utils.clearArray(rawDatas, i)
            __deleteDownloadedFiles(app, outFilePaths)
            return false
        end
        outFilePaths[i] = fullPath
    end
    return true
end



local __ArrayAndCursorMixin =
{
    _mArray     = classlite.declareConstantField(nil),
    _mCursor    = classlite.declareConstantField(nil),

    init = function(self, array)
        self._mArray = array
        self._mCursor = 1
    end,
}

classlite.declareClass(__ArrayAndCursorMixin)


local _Deserializer =
{
    readElement = function(self)
        local ret = self._mArray[self._mCursor]
        self._mCursor = self._mCursor + 1
        return ret
    end,

    readArray = function(self, outArray)
        local count = self:readElement()
        if types.isNumber(count) and count > 0
        then
            utils.clearTable(outArray)
            for i = 1, count
            do
                local elem = self:readElement()
                table.insert(outArray, elem)
            end
            return true
        end
    end,
}

classlite.declareClass(_Deserializer, __ArrayAndCursorMixin)


local _Serializer =
{
    writeElement = function(self, elem)
        self._mArray[self._mCursor] = elem
        self._mCursor = self._mCursor + 1
    end,

    writeArray = function(self, array, hook, arg)
        local count = #array
        self:writeElement(count)
        for i = 1, count
        do
            local val = array[i]
            if hook
            then
                val = hook(val, arg)
            end
            self:writeElement(val)
        end
    end,
}

classlite.declareClass(_Serializer, __ArrayAndCursorMixin)



local IDanmakuSource =
{
    _mApplication   = classlite.declareConstantField(nil),
    _mPlugin        = classlite.declareConstantField(nil),

    setApplication = function(self, app)
        self._mApplication = app
    end,

    getPluginName = function(self)
        local plugin = self._mPlugin
        return plugin and plugin:getName()
    end,

    _serialize = function(self, serializer)
        if serializer and self:_isValid()
        then
            serializer:writeElement(self:getPluginName())
            return true
        end
    end,

    _deserialize = function(self, deserializer)
        if deserializer
        then
            local pluginName = deserializer:readElement()
            local plugin = self._mApplication:getPluginByName(pluginName)
            if plugin
            then
                self._mPlugin = plugin
                return true
            end
        end
    end,

    parse = constants.FUNC_EMPTY,
    getDate = constants.FUNC_EMPTY,
    getDescription = constants.FUNC_EMPTY,

    _init = constants.FUNC_EMPTY,
    _delete = constants.FUNC_EMPTY,
    _update = constants.FUNC_EMPTY,
    _isDuplicated = constants.FUNC_EMPTY,
}

classlite.declareClass(IDanmakuSource)


local _LocalDanmakuSource =
{
    _mPlugin        = classlite.declareConstantField(nil),
    _mFilePath      = classlite.declareConstantField(nil),

    _init = function(self, plugin, filePath)
        self._mPlugin = plugin
        self._mFilePath = filePath
        return self:_isValid()
    end,

    parse = function(self)
        if self:_isValid()
        then
            local plugin = self._mPlugin
            local filePath = self._mFilePath
            local timeOffset = _DEFAULT_START_TIME_OFFSET
            local pools = self._mApplication:getDanmakuPools()
            local sourceID = pools:allocateDanmakuSourceID(plugin:getName(), nil, nil,
                                                           timeOffset, filePath)

            plugin:parseFile(filePath, sourceID, timeOffset)
        end
    end,

    _isValid = function(self)
        return classlite.isInstanceOf(self._mPlugin, pluginbase.IDanmakuSourcePlugin)
            and self._mApplication:isExistedFile(self._mFilePath)
    end,

    getDescription = function(self)
        local filePath = self._mFilePath
        if types.isString(filePath)
        then
            local _, fileName = unportable.splitPath(filePath)
            return fileName
        end
    end,

    _serialize = function(self, serializer)
        if IDanmakuSource._serialize(self, serializer)
        then
            local cacheDir = self._mApplication:getDanmakuSourceRawDataDirPath()
            serializer:writeElement(unportable.getRelativePath(cacheDir, self._mFilePath))
            return true
        end
    end,

    _deserialize = function(self, deserializer)
        if IDanmakuSource._deserialize(self, deserializer)
        then
            local relPath = deserializer:readElement()
            local cacheDir = self._mApplication:getDanmakuSourceRawDataDirPath()
            self._mFilePath = unportable.joinPath(cacheDir, relPath)
            return self:_isValid()
        end
    end,

    _delete = function(self)
        return true
    end,

    _isDuplicated = function(self, source2)
        -- 一个文件不能对应多个弹幕源
        return classlite.isInstanceOf(source2, self:getClass())
            and self._mFilePath == source2._mFilePath
    end,
}

classlite.declareClass(_LocalDanmakuSource, IDanmakuSource)


local _CachedRemoteDanmakuSource =
{
    _mPlugin            = classlite.declareConstantField(nil),
    _mDate              = classlite.declareConstantField(0),
    _mDescription       = classlite.declareConstantField(nil),
    _mVideoIDs          = classlite.declareTableField(),
    _mFilePaths         = classlite.declareTableField(),
    _mStartTimeOffsets  = classlite.declareTableField(),

    _init = function(self, plugin, date, desc, videoIDs, paths, offsets)
        self._mPlugin = plugin
        self._mDate = date
        self._mDescription = desc or constants.STR_EMPTY

        local sourceVideoIDs = utils.clearTable(self._mVideoIDs)
        local sourcePaths = utils.clearTable(self._mFilePaths)
        local sourceOffsets = utils.clearTable(self._mStartTimeOffsets)
        utils.appendArrayElements(sourceVideoIDs, videoIDs)
        utils.appendArrayElements(sourcePaths, paths)
        utils.appendArrayElements(sourceOffsets, offsets)

        -- 对字段排序方便后来更新时比较
        if self:_isValid()
        then
            utils.sortParallelArrays(sourceOffsets, sourceVideoIDs, sourcePaths)
            return true
        end
    end,

    getDate = function(self)
        return self._mDate
    end,

    getDescription = function(self)
        return self._mDescription
    end,

    parse = function(self)
        if self:_isValid()
        then
            local pluginName = self._mPlugin:getName()
            local videoIDs = self._mVideoIDs
            local timeOffsets = self._mStartTimeOffsets
            local pools = self._mApplication:getDanmakuPools()
            for i, filePath in utils.iterateArray(self._mFilePaths)
            do
                local timeOffset = timeOffsets[i]
                local sourceID = pools:allocateDanmakuSourceID(pluginName, videoIDs[i], i, timeOffset)
                self._mPlugin:parseFile(filePath, sourceID, timeOffset)
            end
        end
    end,


    _isValid = function(self)
        local function __checkNonExistedFilePath(path, app)
            return not app:isExistedFile(path)
        end

        local function __checkIsNotNumber(num)
            return not types.isNumber(num)
        end

        local function __checkIsNotString(url)
            return not types.isString(url)
        end

        local app = self._mApplication
        local videoIDs = self._mVideoIDs
        local filePaths = self._mFilePaths
        local timeOffsets = self._mStartTimeOffsets
        return classlite.isInstanceOf(self._mPlugin, pluginbase.IDanmakuSourcePlugin)
            and types.isNumber(self._mDate)
            and types.isString(self._mDescription)
            and #videoIDs > 0
            and #videoIDs == #filePaths
            and #videoIDs == #timeOffsets
            and not utils.linearSearchArrayIf(videoIDs, __checkIsNotString)
            and not utils.linearSearchArrayIf(filePaths, __checkNonExistedFilePath, app)
            and not utils.linearSearchArrayIf(timeOffsets, __checkIsNotNumber)
    end,

    _serialize = function(self, serializer)
        local function __getRelativePath(fullPath, dir)
            return unportable.getRelativePath(dir, fullPath)
        end

        if IDanmakuSource._serialize(self, serializer)
        then
            local cacheDir = self._mApplication:getDanmakuSourceRawDataDirPath()
            serializer:writeElement(self._mDate)
            serializer:writeElement(self._mDescription)
            serializer:writeArray(self._mVideoIDs)
            serializer:writeArray(self._mFilePaths, __getRelativePath, cacheDir)
            serializer:writeArray(self._mStartTimeOffsets)
            return true
        end
    end,

    _deserialize = function(self, deserializer)
        local function __readFilePaths(deserializer, filePaths, dir)
            if deserializer:readArray(filePaths)
            then
                for i, relPath in ipairs(filePaths)
                do
                    filePaths[i] = unportable.joinPath(dir, relPath)
                end
                return true
            end
        end

        if IDanmakuSource._deserialize(self, deserializer)
        then
            local succeed = true
            local cacheDir = self._mApplication:getDanmakuSourceRawDataDirPath()
            self._mDate = deserializer:readElement()
            self._mDescription = deserializer:readElement()
            succeed = succeed and deserializer:readArray(self._mVideoIDs)
            succeed = succeed and __readFilePaths(deserializer, self._mFilePaths, cacheDir)
            succeed = succeed and deserializer:readArray(self._mStartTimeOffsets)
            return self:_isValid()
        end
    end,


    _delete = function(self)
        -- 只要删除原始文件，反序列化的时候就被认为是无效的弹幕源
        local app = self._mApplication
        for _, path in utils.iterateArray(self._mFilePaths)
        do
            app:deleteTree(path)
        end
        return true
    end,


    _update = function(self, source2)
        if self:_isValid()
        then
            local app = self._mApplication
            self:clone(source2)
            source2._mDate = app:getCurrentDateTime()

            local videoIDs = self._mVideoIDs
            local plugin = self._mPlugin
            local filePaths = utils.clearTable(source2._mFilePaths)
            local succeed = __downloadDanmakuRawDataFiles(app, plugin, videoIDs, filePaths)
            if succeed and source2:_isValid()
            then
                return true
            end

            __deleteDownloadedFiles(app, filePaths)
        end
    end,


    _isDuplicated = function(self, source2)
        local function __hasSameArrayContent(array1, array2)
            if types.isTable(array1) and types.isTable(array2) and #array1 == #array2
            then
                for i = 1, #array1
                do
                    if array1[i] ~= array2[i]
                    then
                        return false
                    end
                end
                return true
            end
        end

        return classlite.isInstanceOf(source2, self:getClass())
            and self:_isValid()
            and source2:_isValid()
            and __hasSameArrayContent(self._mVideoIDs, source2._mVideoIDs)
            and __hasSameArrayContent(self._mStartTimeOffsets, source2._mStartTimeOffsets)
    end,
}

classlite.declareClass(_CachedRemoteDanmakuSource, IDanmakuSource)


local _META_CMD_ADD     = 0
local _META_CMD_DELETE  = 1

local _META_SOURCE_TYPE_LOCAL   = 0
local _META_SOURCE_TYPE_CACHED  = 1

local _META_SOURCE_TYPE_CLASS_MAP =
{
    [_META_SOURCE_TYPE_LOCAL]       = _LocalDanmakuSource,
    [_META_SOURCE_TYPE_CACHED]      = _CachedRemoteDanmakuSource,
}

local _META_SOURCE_TYPE_ID_MAP =
{
    [_LocalDanmakuSource]           = _META_SOURCE_TYPE_LOCAL,
    [_CachedRemoteDanmakuSource]    = _META_SOURCE_TYPE_CACHED,
}


local DanmakuSourceManager =
{
    _mApplication               = classlite.declareConstantField(nil),
    _mSerializer                = classlite.declareClassField(_Serializer),
    _mDeserializer              = classlite.declareClassField(_Deserializer),
    _mDanmakuSourcePools        = classlite.declareTableField(),

    __mSerializeArray           = classlite.declareTableField(),
    __mDeserializeArray         = classlite.declareTableField(),
    __mListFilePaths            = classlite.declareTableField(),
    __mDownloadedFilePaths      = classlite.declareTableField(),
    __mDeserializedSources      = classlite.declareTableField(),
    __mReadMetaFileCallback     = classlite.declareTableField(),


    new = function(self)
        self.__mReadMetaFileCallback = function(...)
            return self:__onReadMetaFileTuple(...)
        end
    end,


    dispose = function(self)
        for _, pool in pairs(self._mDanmakuSourcePools)
        do
            utils.forEachArrayElement(pool, utils.disposeSafely)
            utils.clearTable(pool)
        end
    end,


    setApplication = function(self, app)
        self._mApplication = app
    end,


    __onReadMetaFileTuple = function(self, ...)
        local deserializer = self._mDeserializer
        local outSources = self.__mDeserializedSources
        local array = utils.clearTable(self.__mDeserializeArray)
        utils.packArray(array, ...)
        deserializer:init(array)
        self:__deserializeDanmakuSourceCommand(deserializer, outSources)
    end,


    __serializeDanmakuSourceCommand = function(self, serializer, cmdID, source)
        local sourceTypeID = _META_SOURCE_TYPE_ID_MAP[source:getClass()]
        if sourceTypeID
        then
            serializer:writeElement(self._mApplication:getVideoFileMD5())
            serializer:writeElement(cmdID)
            serializer:writeElement(sourceTypeID)
            return source:_serialize(serializer)
        end
    end,


    __deserializeDanmakuSourceCommand = function(self, deserializer, outSources)
        local function __deserializeDanmakuSource(self, deserializer)
            local clzID = deserializer:readElement()
            local sourceClz = clzID and _META_SOURCE_TYPE_CLASS_MAP[clzID]
            if sourceClz
            then
                local source = self:_obtainDanmakuSource(sourceClz)
                if source:_deserialize(deserializer)
                then
                    return source
                end

                self:_recycleDanmakuSource(source)
            end
        end

        if deserializer:readElement() ~= self._mApplication:getVideoFileMD5()
        then
            return
        end

        local cmdID = deserializer:readElement()
        if cmdID == _META_CMD_ADD
        then
            local source = __deserializeDanmakuSource(self, deserializer)
            if source
            then
                table.insert(outSources, source)
                return true
            end
        elseif cmdID == _META_CMD_DELETE
        then
            local source = __deserializeDanmakuSource(self, deserializer)
            if source
            then
                for i, iterSource in utils.reverseIterateArray(outSources)
                do
                    if iterSource:_isDuplicated(source)
                    then
                        table.remove(outSources, i)
                        self:_recycleDanmakuSource(iterSource)
                    end
                end
                self:_recycleDanmakuSource(source)
                return true
            end
        end
    end,


    _obtainDanmakuSource = function(self, srcClz)
        local pool = self._mDanmakuSourcePools[srcClz]
        local ret = pool and utils.popArrayElement(pool) or srcClz:new()
        ret:reset()
        ret:setApplication(self._mApplication)
        return ret
    end,


    _recycleDanmakuSource = function(self, source)
        if classlite.isInstanceOf(source, IDanmakuSource)
        then
            local clz = source:getClass()
            local pools = self._mDanmakuSourcePools
            local pool = pools[pools]
            if not pool
            then
                pool = {}
                pools[clz] = pool
            end
            table.insert(pool, source)
        end
    end,


    recycleDanmakuSources = function(self, danmakuSources)
        for i, source in utils.iterateArray(danmakuSources)
        do
            self:_recycleDanmakuSource(source)
            danmakuSources[i] = nil
        end
    end,


    _doReadMetaFile = function(self, deserializeCallback)
        local path = self._mApplication:getDanmakuSourceMetaDataFilePath()
        serialize.deserializeFromFilePath(path, deserializeCallback)
    end,


    _doAppendMetaFile = function(self, cmdID, source)
        local app = self._mApplication
        local array = utils.clearTable(self.__mSerializeArray)
        local serializer = self._mSerializer
        serializer:init(array)
        if self:__serializeDanmakuSourceCommand(serializer, cmdID, source)
        then
            local metaFilePath = app:getDanmakuSourceMetaDataFilePath()
            if not app:isExistedFile(metaFilePath)
            then
                local dir = unportable.splitPath(metaFilePath)
                local hasCreated = app:isExistedDir(dir) or app:createDir(dir)
                if not hasCreated
                then
                    return
                end
            end

            local file = app:writeFile(metaFilePath, constants.FILE_MODE_WRITE_APPEND)
            serialize.serializeArray(file, array)
            app:closeFile(file)
        end
    end,


    listDanmakuSources = function(self, outList)
        if not types.isTable(outList)
        then
            return
        end

        -- 读取下载过的弹幕源
        local outDanmakuSources = utils.clearTable(self.__mDeserializedSources)
        self:_doReadMetaFile(self.__mReadMetaFileCallback)
        utils.appendArrayElements(outList, outDanmakuSources)
        utils.clearTable(outDanmakuSources)
    end,


    addCachedDanmakuSource = function(self, sources, plugin, desc, videoIDs, offsets)
        local app = self._mApplication
        local datetime = app:getCurrentDateTime()
        local filePaths = utils.clearTable(self.__mDownloadedFilePaths)
        if __downloadDanmakuRawDataFiles(app, plugin, videoIDs, filePaths)
        then
            local source = self:_obtainDanmakuSource(_CachedRemoteDanmakuSource)
            if source and source:_init(plugin, datetime, desc, videoIDs, filePaths, offsets)
            then
                self:_doAppendMetaFile(_META_CMD_ADD, source)
                utils.pushArrayElement(sources, source)
                return source
            end

            self:_recycleDanmakuSource(source)
        end
    end,


    addLocalDanmakuSource = function(self, sources, plugin, filePath)
        local function __isDuplicated(iterSource, newSource)
            return iterSource:_isDuplicated(newSource)
        end

        local newSource = self:_obtainDanmakuSource(_LocalDanmakuSource)
        if newSource:_init(plugin, filePath)
            and not utils.linearSearchArrayIf(sources, __isDuplicated, newSource)
        then
            self:_doAppendMetaFile(_META_CMD_ADD, newSource)
            utils.pushArrayElement(sources, newSource)
            return newSource
        end

        self:_recycleDanmakuSource(newSource)
    end,


    deleteDanmakuSourceByIndex = function(self, sources, idx)
        local source = types.isTable(sources) and types.isNumber(idx) and sources[idx]
        if classlite.isInstanceOf(source, IDanmakuSource) and sources[idx]:_delete()
        then
            -- 因为不能删外部文件来标记删除，所以在持久化文件里记个反操作
            if classlite.isInstanceOf(source, _LocalDanmakuSource)
            then
                self:_doAppendMetaFile(_META_CMD_DELETE, source)
            end

            -- 外部不要再持有这个对象了
            table.remove(sources, idx)
            self:_recycleDanmakuSource(source)
            return true
        end
    end,


    updateDanmakuSources = function(self, inSources, outSources)
        local function __checkIsNotDanmakuSource(source)
            return not classlite.isInstanceOf(source, IDanmakuSource)
        end

        if types.isTable(inSources)
            and types.isTable(outSources)
            and not types.isNilOrEmpty(inSources)
            and not utils.linearSearchArrayIf(inSources, __checkIsNotDanmakuSource)
        then
            -- 注意输入和输出有可能是同一个 table
            local app = self._mApplication
            local tmpSource = self:_obtainDanmakuSource(_CachedRemoteDanmakuSource)
            for i = 1, #inSources
            do
                -- 排除掉一些来源重复的
                local source = inSources[i]
                local found = false
                for j = 1, i - 1
                do
                    if source:_isDuplicated(inSources[j])
                    then
                        found = true
                        break
                    end
                end

                if not found and source:_update(tmpSource)
                then
                    self:_doAppendMetaFile(_META_CMD_ADD, tmpSource)
                    table.insert(outSources, tmpSource)
                    tmpSource = self:_obtainDanmakuSource(_CachedRemoteDanmakuSource)
                end
            end
            self:_recycleDanmakuSource(tmpSource)
        end
    end,
}

classlite.declareClass(DanmakuSourceManager)


return
{
    IDanmakuSource          = IDanmakuSource,
    DanmakuSourceManager    = DanmakuSourceManager,
}

------------------------ src/shell/sourcemgr.lua <END> -------------------------

            end
            requestedModule = src_shell_sourcemgr_lua()
            __loadedModules[path] = requestedModule
        end
        return requestedModule
    end
    if path == "src/shell/uiconstants"
    then
        local requestedModule = __loadedModules[path]
        if not requestedModule
        then
            local function src_shell_uiconstants_lua()


---------------------- src/shell/uiconstants.lua <START> -----------------------
local UI_STRINGS_CN =
{
    title_app                               = "MPVDanmakuLoader",
    title_main                              = "选择操作",
    title_select_plugin                     = "选择插件",
    title_search_danmaku_source             = "输入搜索内容",
    title_select_new_danmaku_source         = "选择添加弹幕源",
    title_delete_danmaku_source             = "选择删除弹幕源",
    title_update_danmaku_source             = "选择更新弹幕源",
    title_generate_ass_file                 = "选择播放的弹幕源",

    column_sources_date                     = "添加日期",
    column_sources_plugin_name              = "插件名",
    column_sources_description              = "备注",

    option_main_add_local_danmaku_source    = "添加弹幕源",
    option_main_search_danmaku_source       = "搜索弹幕源",
    option_main_update_danmaku_source       = "更新弹幕源",
    option_main_generate_ass_file           = "生成弹幕",
    option_main_delete_danmaku_source       = "删除弹幕源",

    datetime_unknown                        = "N/A",

    fmt_select_new_danmaku_source_header    = "标题%d",
    fmt_danmaku_source_datetime             = "%y/%m/%d %H:%M",

    load_progress_search                    = "正在搜索弹幕",
    load_progress_download                  = "正在下载弹幕",
    load_progress_parse                     = "正在解释弹幕",
    load_progress_failed                    = "加载失败",
    load_progress_succeed                   = "加载成功",

    select_subtitle_should_replace          = "是否替换当前字幕？",
    select_subtitle_ok                      = "是",
    select_subtitle_cancel                  = "否",
}


local UI_SIZES_ZENITY =
{
    main                        = { 280, 280 },
    select_new_danmaku_source   = { 500, 600 },
    show_danmaku_sources        = { 500, 600 },
    select_plugin               = { 300, 400 },
}


return
{
    UI_STRINGS_CN       = UI_STRINGS_CN,
    UI_SIZES_ZENITY     = UI_SIZES_ZENITY,
}
----------------------- src/shell/uiconstants.lua <END> ------------------------

            end
            requestedModule = src_shell_uiconstants_lua()
            __loadedModules[path] = requestedModule
        end
        return requestedModule
    end

    return _G.require(path)
end


-------------------------- src/shell/main.lua <START> --------------------------
local _gConfiguration       = nil
local _gApplication         = nil
local _gLoaderShell         = nil
local _gOpenedURL           = nil
local _gOpenedFilePath      = nil
local _gIsAppInitialized    = false


local function __ensureApplication()
    local app = _gApplication
    if not app
    then
        local application = require("src/shell/application")
        app = application.MPVDanmakuLoaderApp:new()
        _gApplication = app
    end

    if not _gIsAppInitialized
    then
        _gIsAppInitialized = true
        app:init(_gOpenedFilePath)
    end

    app:updateConfiguration()
    return app
end


local function __ensureLoaderShell(app)
    local shell = _gLoaderShell
    if not shell
    then
        local logic = require("src/shell/logic")
        shell = logic.MPVDanmakuLoaderShell:new()
        _gLoaderShell = shell
    end
    shell:setApplication(app)
    return shell
end


local function __doRunKeyBindingCallback(func)
    local app = __ensureApplication()
    local cfg = app:getConfiguration()
    app:setLogFunction(cfg.showDebugLog and print)

    local shell = __ensureLoaderShell(app)
    local isPausedBefore = mp.get_property_native("pause")
    mp.set_property_native("pause", cfg.pauseWhileShowing and true or isPausedBefore)
    func(cfg, app, shell)
    mp.set_property_native("pause", isPausedBefore)
end


local function __onRequestDanmaku()
    local function __func1(cfg, app, shell)
        shell:showMainWindow()
    end

    local function __func2(cfg, app, shell)
        shell:loadDanmakuFromURL(_gOpenedURL)
    end

    if _gOpenedFilePath
    then
        __doRunKeyBindingCallback(__func1)
    elseif _gOpenedURL
    then
        __doRunKeyBindingCallback(__func2)
    end
end


local function __markOpenedPath()
    _gOpenedURL = nil
    _gOpenedFilePath = nil
    _gIsAppInitialized = false

    local path = mp.get_property("stream-open-filename")
    local isURL = path:match(".*://.*")
    if isURL
    then
        _gOpenedURL = path
    else
        local isFullPath = path:match("^/.+$")
        local fullPath = isFullPath and path or mp.utils.join_path(mp.utils.getcwd(), path)
        _gOpenedFilePath = fullPath
    end
end


-- 如果传网址会经过 youtube-dl 分析并重定向，为了拿到最初的网址必须加回调
mp.add_hook("on_load", 5, __markOpenedPath)
mp.add_key_binding("Ctrl+d", "load", __onRequestDanmaku)
--------------------------- src/shell/main.lua <END> ---------------------------
