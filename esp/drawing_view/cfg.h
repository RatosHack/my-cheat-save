#import <Foundation/Foundation.h>

extern float g_menuR, g_menuG, g_menuB;
extern float g_textR, g_textG, g_textB;
extern volatile float esp_box_r, esp_box_g, esp_box_b;
extern volatile float esp_line_r, esp_line_g, esp_line_b;

NSString *cfg_get_dir(void);
NSArray<NSString *> *cfg_get_list(void);
void cfg_create(NSString *name);
void cfg_load(NSString *name);
void cfg_delete(NSString *name);
