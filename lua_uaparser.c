#define LUA_LIB
#include <lua.h>
#include <lauxlib.h>
#include "uap/uap.h"
#include "regexes.yaml.h"

static int linit(lua_State *L) {
    struct uap_parser *ua_parser = uap_parser_create();
    uap_parser_read_buffer(ua_parser, ___uap_core_regexes_yaml,
                           ___uap_core_regexes_yaml_len);
    lua_pushlightuserdata(L, ua_parser);
    lua_setfield(L, LUA_REGISTRYINDEX, "parser");
    return 0;
}

static int lparse(lua_State *L) {
    const char *ua = luaL_checkstring(L, 1);
    lua_pop(L, 1);
    if (ua == NULL) luaL_error(L, "ua is NULL");
    lua_getfield(L, LUA_REGISTRYINDEX, "parser");
    struct uap_parser *ua_parser = (struct uap_parser *)lua_touserdata(L, -1);
    lua_pop(L, 1);
    struct uap_useragent_info *ua_info = uap_useragent_info_create();
    if (!uap_parser_parse_string(ua_parser, ua_info, ua)) {
        luaL_error(L, "ua parse failed: %s", ua);
    }
    lua_createtable(L, 0, 3);
    lua_createtable(L, 0, 3);
    lua_pushstring(L, ua_info->os.family);
    lua_setfield(L, -2, "family");
    uap_useragent_info_destroy(ua_info);
    return 1;
}

static int ldestroy(lua_State *L) {
    lua_getfield(L, LUA_REGISTRYINDEX, "parser");
    struct uap_parser *ua_parser = (struct uap_parser *)lua_touserdata(L, -1);
    uap_parser_destroy(ua_parser);
    lua_pushnil(L);
    lua_setfield(L, LUA_REGISTRYINDEX, "parser");
    return 0;
}

LUAMOD_API int luaopen_uaparser(lua_State *L) {
    luaL_Reg l[] = {
        {"init", linit},
        {"parse", lparse},
        {"destroy", ldestroy},
        {NULL, NULL},
    };
    luaL_checkversion(L);
    luaL_newlib(L, l);
    return 1;
}
