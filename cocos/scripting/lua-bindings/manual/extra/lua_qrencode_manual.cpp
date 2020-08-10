#include <stdlib.h>

#include "scripting/lua-bindings/manual/extra/lua_qrencode_manual.h"
#include "external/qrencode/qrencode.h"
#include "platform/CCFileUtils.h"
#include "png.h"
using namespace cocos2d;
#define INCHES_PER_METER (100.0/2.54)

static int casesensitive = 1;
static int eightbit = 0;
static int version = 0;
static int size = 3;
static int margin = 1;
static int dpi = 72;
static int structured = 0;
static int rle = 0;
static int svg_path = 0;
static int micro = 0;
static QRecLevel level = QR_ECLEVEL_L;
static QRencodeMode mode = QR_MODE_8;
static unsigned char fg_color[4] = {0, 0, 0, 255};
static unsigned char bg_color[4] = {255, 255, 255, 255};

static int verbose = 0;

enum imageType {
    PNG_TYPE,
    PNG32_TYPE
};

static enum imageType image_type = PNG_TYPE;

static void fillRow(unsigned char *row, int num, const unsigned char color[])
{
    int i;

    for(i = 0; i < num; i++) {
        memcpy(row, color, 4);
        row += 4;
    }
}
static bool writePNG(lua_State* tolua_S,const QRcode *qrcode, const char *outfile, enum imageType type)
{

	static FILE *fp; // avoid clobbering by setjmp.
	png_structp png_ptr;
	png_infop info_ptr;
	png_colorp palette = NULL;
	png_byte alpha_values[2];
	unsigned char *row, *p, *q;
	int x, y, xx, yy, bit;
	int realwidth;

	realwidth = (qrcode->width + margin * 2) * size;
	if(type == PNG_TYPE) {
		row = (unsigned char *)malloc((realwidth + 7) / 8);
	} else if(type == PNG32_TYPE) {
		row = (unsigned char *)malloc(realwidth * 4);
	} else {
		luaL_error(tolua_S, "Internal error.\n");
		return false;
	}
	if(row == NULL) {
		luaL_error(tolua_S, "Failed to allocate memory.\n");
		return false;
	}
	fp = fopen(FileUtils::getInstance()->getSuitableFOpen(outfile).c_str(), "wb");
	if(fp == NULL) {
			luaL_error(tolua_S, "Failed to create file: %s\n", outfile);
			
			return false;
	}
	png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
	if(png_ptr == NULL) {
		luaL_error(tolua_S, "Failed to initialize PNG writer.");
		return false;
	}

	info_ptr = png_create_info_struct(png_ptr);
	if(info_ptr == NULL) {
		luaL_error(tolua_S, "Failed to initialize PNG writer.");
		return false;
	}

	if(setjmp(png_jmpbuf(png_ptr))) {
		png_destroy_write_struct(&png_ptr, &info_ptr);
		luaL_error(tolua_S, "Failed to write PNG image.\n");
		return false;
	}

	if(type == PNG_TYPE) {
		palette = (png_colorp) malloc(sizeof(png_color) * 2);
		if(palette == NULL) {
			luaL_error(tolua_S, "Failed to allocate memory.\n");
			return false;
		}
		palette[0].red   = fg_color[0];
		palette[0].green = fg_color[1];
		palette[0].blue  = fg_color[2];
		palette[1].red   = bg_color[0];
		palette[1].green = bg_color[1];
		palette[1].blue  = bg_color[2];
		alpha_values[0] = fg_color[3];
		alpha_values[1] = bg_color[3];
		png_set_PLTE(png_ptr, info_ptr, palette, 2);
		png_set_tRNS(png_ptr, info_ptr, alpha_values, 2, NULL);
	}

	png_init_io(png_ptr, fp);
	if(type == PNG_TYPE) {
		png_set_IHDR(png_ptr, info_ptr,
				realwidth, realwidth,
				1,
				PNG_COLOR_TYPE_PALETTE,
				PNG_INTERLACE_NONE,
				PNG_COMPRESSION_TYPE_DEFAULT,
				PNG_FILTER_TYPE_DEFAULT);
	} else {
		png_set_IHDR(png_ptr, info_ptr,
				realwidth, realwidth,
				8,
				PNG_COLOR_TYPE_RGB_ALPHA,
				PNG_INTERLACE_NONE,
				PNG_COMPRESSION_TYPE_DEFAULT,
				PNG_FILTER_TYPE_DEFAULT);
	}
	png_set_pHYs(png_ptr, info_ptr,
			dpi * INCHES_PER_METER,
			dpi * INCHES_PER_METER,
			PNG_RESOLUTION_METER);
	png_write_info(png_ptr, info_ptr);

	if(type == PNG_TYPE) {
	/* top margin */
		memset(row, 0xff, (realwidth + 7) / 8);
		for(y = 0; y < margin * size; y++) {
			png_write_row(png_ptr, row);
		}

		/* data */
		p = qrcode->data;
		for(y = 0; y < qrcode->width; y++) {
			memset(row, 0xff, (realwidth + 7) / 8);
			q = row;
			q += margin * size / 8;
			bit = 7 - (margin * size % 8);
			for(x = 0; x < qrcode->width; x++) {
				for(xx = 0; xx < size; xx++) {
					*q ^= (*p & 1) << bit;
					bit--;
					if(bit < 0) {
						q++;
						bit = 7;
					}
				}
				p++;
			}
			for(yy = 0; yy < size; yy++) {
				png_write_row(png_ptr, row);
			}
		}
		/* bottom margin */
		memset(row, 0xff, (realwidth + 7) / 8);
		for(y = 0; y < margin * size; y++) {
			png_write_row(png_ptr, row);
		}
	} else {
	/* top margin */
		fillRow(row, realwidth, bg_color);
		for(y = 0; y < margin * size; y++) {
			png_write_row(png_ptr, row);
		}

		/* data */
		p = qrcode->data;
		for(y = 0; y < qrcode->width; y++) {
			fillRow(row, realwidth, bg_color);
			for(x = 0; x < qrcode->width; x++) {
				for(xx = 0; xx < size; xx++) {
					if(*p & 1) {
						memcpy(&row[((margin + x) * size + xx) * 4], fg_color, 4);
					}
				}
				p++;
			}
			for(yy = 0; yy < size; yy++) {
				png_write_row(png_ptr, row);
			}
		}
		/* bottom margin */
		fillRow(row, realwidth, bg_color);
		for(y = 0; y < margin * size; y++) {
			png_write_row(png_ptr, row);
		}
	}

	png_write_end(png_ptr, info_ptr);
	png_destroy_write_struct(&png_ptr, &info_ptr);

	fclose(fp);
	free(row);
	free(palette);

	return true;

}
static int tolua_extra_QREncode_encode_write_to_png(lua_State* tolua_S)
{
#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
	if (
			!tolua_isusertable(tolua_S,1,"qrcode",0,&tolua_err) ||
			!tolua_isstring(tolua_S,2,0,&tolua_err) ||
			!tolua_isstring(tolua_S,3,0,&tolua_err)
	   )
		goto tolua_lerror;
	else
#endif
	{
		const char *intext = (const char*)tolua_tostring(tolua_S,2,0);
		const char *path = (const char*)tolua_tostring(tolua_S,3,0);
		version = tolua_tonumber(tolua_S, 4,version);
		casesensitive = tolua_toboolean(tolua_S, 5,casesensitive);

		static const QRencodeMode modes[] = {QR_MODE_NUM,QR_MODE_AN,QR_MODE_KANJI,QR_MODE_8,QR_MODE_STRUCTURE,QR_MODE_ECI,QR_MODE_FNC1FIRST,QR_MODE_FNC1SECOND,QR_MODE_NUL};
		static const char *const modenames[] = {"QR_MODE_NUM",
		 "QR_MODE_AN", "QR_MODE_KANJI","QR_MODE_8", "QR_MODE_STRUCTURE", 
		 "QR_MODE_ECI","QR_MODE_FNC1FIRST","QR_MODE_FNC1SECOND","QR_MODE_NUL", NULL};
		//默认
		
		if(lua_gettop(tolua_S)>=abs(6)){
			int mode_op = luaL_checkoption(tolua_S, 6, "QR_MODE_8", modenames);
			mode = modes[mode_op];
		}
		

		static const QRecLevel levels[] = {QR_ECLEVEL_L, QR_ECLEVEL_M, QR_ECLEVEL_Q, QR_ECLEVEL_H};
		static const char *const levelnames[] = {"QR_ECLEVEL_L", "QR_ECLEVEL_M", "QR_ECLEVEL_Q", "QR_ECLEVEL_H", NULL};

		//默认级别
		
    	if(lua_gettop(tolua_S)>=abs(7)){
			int level_op = luaL_checkoption(tolua_S, 7, "QR_ECLEVEL_H", levelnames);
			level = levels[level_op];
		}
		QRcode *qrcode = QRcode_encodeString((char *)intext, version, level, mode, casesensitive);

		writePNG(tolua_S,qrcode,path,image_type);
		
	}
	return 1;
#if COCOS2D_DEBUG >= 1
tolua_lerror:
	tolua_error(tolua_S,"#ferror  in function 'encode_write_to_png'.",&tolua_err);
	return 0;
#endif
}

/* Open function */
TOLUA_API int register_qrencode_module(lua_State* tolua_S)
{
	tolua_open(tolua_S);
	tolua_usertype(tolua_S, "qrcode");
	tolua_module(tolua_S, "cc", 0);
	tolua_beginmodule(tolua_S, "cc");
	tolua_cclass(tolua_S, "qrcode", "qrcode", "", NULL);
	tolua_beginmodule(tolua_S, "qrcode");

	tolua_function(tolua_S, "encode_write_to_png", tolua_extra_QREncode_encode_write_to_png);
	tolua_endmodule(tolua_S);
	tolua_endmodule(tolua_S);
	return 1;
}
