#import <UIKit/UIKit.h>

extern volatile bool esp_box_enabled;
extern volatile bool esp_box_outline;
extern volatile bool esp_box_fill;
extern volatile bool esp_box_corner;
extern volatile bool esp_box_3d;
extern volatile bool esp_box_3d_corner;
extern volatile float esp_box_r;
extern volatile float esp_box_g;
extern volatile float esp_box_b;
extern volatile float esp_box_thickness;
extern volatile float esp_box3d_thickness;
extern volatile float esp_skeleton_thickness;
extern volatile float esp_skeleton_r;
extern volatile float esp_skeleton_g;
extern volatile float esp_skeleton_b;
extern volatile float esp_line_r;
extern volatile float esp_line_g;
extern volatile float esp_line_b;
extern volatile float esp_name_r;
extern volatile float esp_name_g;
extern volatile float esp_name_b;
extern volatile float esp_health_r;
extern volatile float esp_health_g;
extern volatile float esp_health_b;
extern volatile float esp_weapon_r;
extern volatile float esp_weapon_g;
extern volatile float esp_weapon_b;
extern volatile float esp_fov_r;
extern volatile float esp_fov_g;
extern volatile float esp_fov_b;
extern volatile bool  esp_arrows_enabled;
extern volatile float esp_arrows_r;
extern volatile float esp_arrows_g;
extern volatile float esp_arrows_b;
extern volatile float esp_arrows_margin;
extern volatile float esp_arrows_size;
extern volatile bool  esp_arrows_outline;
extern volatile float esp_arrows_outline_r;
extern volatile float esp_arrows_outline_g;
extern volatile float esp_arrows_outline_b;
extern volatile bool esp_line_enabled;
extern volatile bool esp_line_outline;
extern volatile int  esp_line_mode;
extern volatile bool esp_invisible;
extern volatile bool esp_addscore;
extern volatile bool esp_inf_ammo;
extern volatile bool esp_no_spread;
extern volatile bool esp_air_jump;
extern volatile bool esp_fast_knife;
extern volatile bool esp_bunny_hop;
extern volatile bool esp_wallshot;
extern volatile bool esp_fire_rate;
extern volatile bool esp_team_check;

extern volatile bool aimbot_enabled;
extern volatile bool aimbot_visible_check;
extern volatile bool aimbot_shooting_check;
extern volatile bool aimbot_knife_bot;
extern volatile float aimbot_smooth;
extern volatile float aimbot_trigger_delay;
extern volatile int   aimbot_bone_index;   

extern volatile bool  esp_rcs_enabled;
extern volatile float esp_rcs_h;
extern volatile float esp_rcs_v;

extern volatile int   esp_bhop_setting;
extern volatile bool  aimbot_triggerbot;
extern volatile bool  aimbot_fov_visible;
extern volatile float aimbot_fov;
extern volatile bool  aimbot_team_check;
extern volatile bool  esp_name_enabled;
extern volatile bool  esp_name_outline;
extern volatile bool  esp_health_enabled;
extern volatile bool  esp_health_bar_enabled;
extern volatile bool  esp_health_bar_outline;
extern volatile bool esp_weapon_enabled;
extern volatile bool esp_weapon_icon_enabled;
extern volatile bool esp_platform_enabled;
extern volatile bool esp_avatar_enabled;

extern volatile bool  viewmodel_enabled;
extern volatile float viewmodel_x;
extern volatile float viewmodel_y;
extern volatile float viewmodel_z;

extern volatile bool esp_auto_load;
extern volatile bool esp_hit_sound_enabled;
extern volatile bool esp_rainbow;
extern volatile bool esp_skeleton_enabled;
extern volatile bool esp_skeleton_head;
extern NSString *esp_selected_config;
extern volatile int esp_menu_effect; // 0=выкл, 1=снег, 2=дождь
extern volatile bool esp_preview_window;
extern volatile int esp_update_rate; // ESP update rate: 30/40/45/50/55/60 // Preview window toggle
