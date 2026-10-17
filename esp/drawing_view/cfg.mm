#import "cfg.h"
#import "tt.h"
#include "obfusheader.h"

extern volatile bool esp_screenshot_safe;
extern volatile bool esp_skeleton_enabled;
extern volatile bool esp_skeleton_head;

NSString *cfg_get_dir() {
    NSString *docs = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *confDir = [docs stringByAppendingPathComponent:@(OBF("wxr"))];
    [[NSFileManager defaultManager] createDirectoryAtPath:confDir withIntermediateDirectories:YES attributes:nil error:nil];

    // Миграция старых .plist файлов → wxr_conf_*.confing
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:confDir error:nil];
    for (NSString *f in files) {
        if ([f hasSuffix:@".plist"]) {
            NSString *oldPath = [confDir stringByAppendingPathComponent:f];
            NSString *baseName = [f stringByDeletingPathExtension];
            NSString *newName = [NSString stringWithFormat:@"wxr_conf_%@.confing", baseName];
            NSString *newPath = [confDir stringByAppendingPathComponent:newName];
            if (![[NSFileManager defaultManager] fileExistsAtPath:newPath]) {
                [[NSFileManager defaultManager] copyItemAtPath:oldPath toPath:newPath error:nil];
            }
            [[NSFileManager defaultManager] removeItemAtPath:oldPath error:nil];
        }
    }
    return confDir;
}

NSArray<NSString*> *cfg_get_list() {
    NSString *confDir = cfg_get_dir();
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:confDir error:nil];
    NSMutableArray *configs = [NSMutableArray array];
    for (NSString *f in files) {
        if ([f hasSuffix:@".confing"]) {
            NSString *displayName = [f stringByDeletingPathExtension];
            if ([displayName hasPrefix:@"wxr_conf_"])
                displayName = [displayName substringFromIndex:9];
            [configs addObject:displayName];
        }
    }
    return configs;
}

void cfg_create(NSString *name) {
    if (name.length == 0) return;
    NSString *fileName = [NSString stringWithFormat:@"wxr_conf_%@.confing", name];
    NSString *path = [cfg_get_dir() stringByAppendingPathComponent:fileName];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    dict[@(OBF("esp_box_enabled"))] = @(esp_box_enabled);
    dict[@(OBF("esp_box_outline"))] = @(esp_box_outline);
    dict[@(OBF("esp_box_fill"))] = @(esp_box_fill);
    dict[@(OBF("esp_box_corner"))] = @(esp_box_corner);
    dict[@(OBF("esp_box_3d"))] = @(esp_box_3d);
    dict[@(OBF("esp_line_enabled"))] = @(esp_line_enabled);
    dict[@(OBF("esp_line_outline"))] = @(esp_line_outline);
    dict[@(OBF("esp_line_mode"))]    = @(esp_line_mode);
    dict[@(OBF("esp_invisible"))] = @(esp_invisible);
    dict[@(OBF("esp_addscore"))] = @(esp_addscore);
    dict[@(OBF("esp_inf_ammo"))] = @(esp_inf_ammo);
    dict[@(OBF("esp_no_spread"))] = @(esp_no_spread);
    dict[@(OBF("esp_air_jump"))] = @(esp_air_jump);
    dict[@(OBF("esp_fast_knife"))] = @(esp_fast_knife);
    dict[@(OBF("esp_bunny_hop"))] = @(esp_bunny_hop);
    dict[@(OBF("esp_wallshot"))] = @(esp_wallshot);
    dict[@(OBF("esp_fire_rate"))] = @(esp_fire_rate);
    dict[@(OBF("esp_team_check"))] = @(esp_team_check);
    
    dict[@(OBF("aimbot_enabled"))] = @(aimbot_enabled);
    dict[@(OBF("aimbot_visible_check"))] = @(aimbot_visible_check);
    dict[@(OBF("aimbot_shooting_check"))] = @(aimbot_shooting_check);
    dict[@(OBF("aimbot_knife_bot"))] = @(aimbot_knife_bot);
    dict[@(OBF("aimbot_smooth"))] = @(aimbot_smooth);
    dict[@(OBF("aimbot_trigger_delay"))] = @(aimbot_trigger_delay);
    dict[@(OBF("aimbot_bone_index"))] = @(aimbot_bone_index);
    
    dict[@(OBF("esp_rcs_enabled"))] = @(esp_rcs_enabled);
    dict[@(OBF("esp_rcs_h"))] = @(esp_rcs_h);
    dict[@(OBF("esp_rcs_v"))] = @(esp_rcs_v);
    
    dict[@(OBF("esp_bhop_setting"))] = @(esp_bhop_setting);
    dict[@(OBF("aimbot_triggerbot"))] = @(aimbot_triggerbot);
    dict[@(OBF("aimbot_fov_visible"))] = @(aimbot_fov_visible);
    dict[@(OBF("aimbot_fov"))] = @(aimbot_fov);
    dict[@(OBF("aimbot_team_check"))] = @(aimbot_team_check);
    dict[@(OBF("esp_name_enabled"))] = @(esp_name_enabled);
    dict[@(OBF("esp_name_outline"))] = @(esp_name_outline);
    dict[@(OBF("esp_health_enabled"))] = @(esp_health_enabled);
    dict[@(OBF("esp_health_bar_enabled"))] = @(esp_health_bar_enabled);
    dict[@(OBF("esp_health_bar_outline"))] = @(esp_health_bar_outline);
    dict[@(OBF("esp_weapon_enabled"))] = @(esp_weapon_enabled);
    dict[@(OBF("esp_weapon_icon_enabled"))] = @(esp_weapon_icon_enabled);
    dict[@(OBF("esp_platform_enabled"))] = @(esp_platform_enabled);
    dict[@(OBF("esp_avatar_enabled"))] = @(esp_avatar_enabled);
    
    dict[@(OBF("viewmodel_enabled"))] = @(viewmodel_enabled);
    dict[@(OBF("viewmodel_x"))] = @(viewmodel_x);
    dict[@(OBF("viewmodel_y"))] = @(viewmodel_y);
    dict[@(OBF("viewmodel_z"))] = @(viewmodel_z);

    dict[@(OBF("esp_auto_load"))] = @(esp_auto_load);
    dict[@(OBF("esp_screenshot_safe"))] = @(esp_screenshot_safe);
    dict[@(OBF("hit_sound"))] = @(esp_hit_sound_enabled);
    dict[@(OBF("skeleton_en"))]   = @(esp_skeleton_enabled);
    dict[@(OBF("skeleton_head"))] = @(esp_skeleton_head);
    dict[@(OBF("menu_effect"))] = @(esp_menu_effect);
    dict[@(OBF("preview_window"))] = @(esp_preview_window);
    dict[@(OBF("update_rate"))] = @(esp_update_rate);

    // Colors
    dict[@"menu_r"] = @(g_menuR); dict[@"menu_g"] = @(g_menuG); dict[@"menu_b"] = @(g_menuB);
    dict[@"text_r"] = @(g_textR); dict[@"text_g"] = @(g_textG); dict[@"text_b"] = @(g_textB);
    dict[@"box_r"]  = @(esp_box_r);  dict[@"box_g"]  = @(esp_box_g);  dict[@"box_b"]  = @(esp_box_b);
    dict[@"box_thick"]   = @((float)esp_box_thickness);
    dict[@"box3d_thick"] = @((float)esp_box3d_thickness);
    dict[@"skel_thick"]  = @((float)esp_skeleton_thickness);
    dict[@"skel_r"] = @(esp_skeleton_r); dict[@"skel_g"] = @(esp_skeleton_g); dict[@"skel_b"] = @(esp_skeleton_b);
    dict[@"line_r"] = @(esp_line_r); dict[@"line_g"] = @(esp_line_g); dict[@"line_b"] = @(esp_line_b);
    dict[@"name_r"] = @(esp_name_r); dict[@"name_g"] = @(esp_name_g); dict[@"name_b"] = @(esp_name_b);
    dict[@"health_r"] = @(esp_health_r); dict[@"health_g"] = @(esp_health_g); dict[@"health_b"] = @(esp_health_b);
    dict[@"weapon_r"] = @(esp_weapon_r); dict[@"weapon_g"] = @(esp_weapon_g); dict[@"weapon_b"] = @(esp_weapon_b);
    dict[@"fov_r"] = @(esp_fov_r); dict[@"fov_g"] = @(esp_fov_g); dict[@"fov_b"] = @(esp_fov_b);
    dict[@"arr_en"]   = @((BOOL)esp_arrows_enabled);
    dict[@"arr_ol"]   = @((BOOL)esp_arrows_outline);
    dict[@"arr_marg"] = @((float)esp_arrows_margin);
    dict[@"arr_size"] = @((float)esp_arrows_size);
    dict[@"ar"]       = @((float)esp_arrows_r);
    dict[@"ag"]       = @((float)esp_arrows_g);
    dict[@"ab"]       = @((float)esp_arrows_b);

    [dict writeToFile:path atomically:YES];
}

void cfg_load(NSString *name) {
    if (name.length == 0) return;
    NSString *fileName = [NSString stringWithFormat:@"wxr_conf_%@.confing", name];
    NSString *path = [cfg_get_dir() stringByAppendingPathComponent:fileName];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    if (!dict) return;
    
    if (dict[@(OBF("esp_box_enabled"))]) esp_box_enabled = [dict[@(OBF("esp_box_enabled"))] boolValue];
    if (dict[@(OBF("esp_box_outline"))]) esp_box_outline = [dict[@(OBF("esp_box_outline"))] boolValue];
    if (dict[@(OBF("esp_box_fill"))]) esp_box_fill = [dict[@(OBF("esp_box_fill"))] boolValue];
    if (dict[@(OBF("esp_box_corner"))]) esp_box_corner = [dict[@(OBF("esp_box_corner"))] boolValue];
    if (dict[@(OBF("esp_box_3d"))]) esp_box_3d = [dict[@(OBF("esp_box_3d"))] boolValue];
    if (dict[@(OBF("esp_line_enabled"))]) esp_line_enabled = [dict[@(OBF("esp_line_enabled"))] boolValue];
    if (dict[@(OBF("esp_line_outline"))]) esp_line_outline = [dict[@(OBF("esp_line_outline"))] boolValue];
    if (dict[@(OBF("esp_line_mode"))])    esp_line_mode    = [dict[@(OBF("esp_line_mode"))]    intValue];
    if (dict[@(OBF("esp_invisible"))]) esp_invisible = [dict[@(OBF("esp_invisible"))] boolValue];
    if (dict[@(OBF("esp_addscore"))]) esp_addscore = [dict[@(OBF("esp_addscore"))] boolValue];
    if (dict[@(OBF("esp_inf_ammo"))]) esp_inf_ammo = [dict[@(OBF("esp_inf_ammo"))] boolValue];
    if (dict[@(OBF("esp_no_spread"))]) esp_no_spread = [dict[@(OBF("esp_no_spread"))] boolValue];
    if (dict[@(OBF("esp_air_jump"))]) esp_air_jump = [dict[@(OBF("esp_air_jump"))] boolValue];
    if (dict[@(OBF("esp_fast_knife"))]) esp_fast_knife = [dict[@(OBF("esp_fast_knife"))] boolValue];
    if (dict[@(OBF("esp_bunny_hop"))]) esp_bunny_hop = [dict[@(OBF("esp_bunny_hop"))] boolValue];
    if (dict[@(OBF("esp_wallshot"))]) esp_wallshot = [dict[@(OBF("esp_wallshot"))] boolValue];
    if (dict[@(OBF("esp_fire_rate"))]) esp_fire_rate = [dict[@(OBF("esp_fire_rate"))] boolValue];
    if (dict[@(OBF("esp_team_check"))]) esp_team_check = [dict[@(OBF("esp_team_check"))] boolValue];
    
    if (dict[@(OBF("aimbot_enabled"))]) aimbot_enabled = [dict[@(OBF("aimbot_enabled"))] boolValue];
    if (dict[@(OBF("aimbot_visible_check"))]) aimbot_visible_check = [dict[@(OBF("aimbot_visible_check"))] boolValue];
    if (dict[@(OBF("aimbot_shooting_check"))]) aimbot_shooting_check = [dict[@(OBF("aimbot_shooting_check"))] boolValue];
    if (dict[@(OBF("aimbot_knife_bot"))]) aimbot_knife_bot = [dict[@(OBF("aimbot_knife_bot"))] boolValue];
    if (dict[@(OBF("aimbot_smooth"))]) aimbot_smooth = [dict[@(OBF("aimbot_smooth"))] floatValue];
    if (dict[@(OBF("aimbot_trigger_delay"))]) aimbot_trigger_delay = [dict[@(OBF("aimbot_trigger_delay"))] floatValue];
    if (dict[@(OBF("aimbot_bone_index"))]) aimbot_bone_index = [dict[@(OBF("aimbot_bone_index"))] intValue];
    
    if (dict[@(OBF("esp_rcs_enabled"))]) esp_rcs_enabled = [dict[@(OBF("esp_rcs_enabled"))] boolValue];
    if (dict[@(OBF("esp_rcs_h"))]) esp_rcs_h = [dict[@(OBF("esp_rcs_h"))] floatValue];
    if (dict[@(OBF("esp_rcs_v"))]) esp_rcs_v = [dict[@(OBF("esp_rcs_v"))] floatValue];
    
    if (dict[@(OBF("esp_bhop_setting"))]) esp_bhop_setting = [dict[@(OBF("esp_bhop_setting"))] intValue];
    if (dict[@(OBF("aimbot_triggerbot"))]) aimbot_triggerbot = [dict[@(OBF("aimbot_triggerbot"))] boolValue];
    if (dict[@(OBF("aimbot_fov_visible"))]) aimbot_fov_visible = [dict[@(OBF("aimbot_fov_visible"))] boolValue];
    if (dict[@(OBF("aimbot_fov"))]) aimbot_fov = [dict[@(OBF("aimbot_fov"))] floatValue];
    if (dict[@(OBF("aimbot_team_check"))]) aimbot_team_check = [dict[@(OBF("aimbot_team_check"))] boolValue];
    if (dict[@(OBF("esp_name_enabled"))]) esp_name_enabled = [dict[@(OBF("esp_name_enabled"))] boolValue];
    if (dict[@(OBF("esp_name_outline"))]) esp_name_outline = [dict[@(OBF("esp_name_outline"))] boolValue];
    if (dict[@(OBF("esp_health_enabled"))]) esp_health_enabled = [dict[@(OBF("esp_health_enabled"))] boolValue];
    if (dict[@(OBF("esp_health_bar_enabled"))]) esp_health_bar_enabled = [dict[@(OBF("esp_health_bar_enabled"))] boolValue];
    if (dict[@(OBF("esp_health_bar_outline"))]) esp_health_bar_outline = [dict[@(OBF("esp_health_bar_outline"))] boolValue];
    if (dict[@(OBF("esp_weapon_enabled"))]) esp_weapon_enabled = [dict[@(OBF("esp_weapon_enabled"))] boolValue];
    if (dict[@(OBF("esp_weapon_icon_enabled"))]) esp_weapon_icon_enabled = [dict[@(OBF("esp_weapon_icon_enabled"))] boolValue];
    if (dict[@(OBF("esp_platform_enabled"))]) esp_platform_enabled = [dict[@(OBF("esp_platform_enabled"))] boolValue];
    if (dict[@(OBF("esp_avatar_enabled"))]) esp_avatar_enabled = [dict[@(OBF("esp_avatar_enabled"))] boolValue];
    
    if (dict[@(OBF("viewmodel_enabled"))]) viewmodel_enabled = [dict[@(OBF("viewmodel_enabled"))] boolValue];
    if (dict[@(OBF("viewmodel_x"))]) viewmodel_x = [dict[@(OBF("viewmodel_x"))] floatValue];
    if (dict[@(OBF("viewmodel_y"))]) viewmodel_y = [dict[@(OBF("viewmodel_y"))] floatValue];
    if (dict[@(OBF("viewmodel_z"))]) viewmodel_z = [dict[@(OBF("viewmodel_z"))] floatValue];
    
    if (dict[@(OBF("esp_auto_load"))]) esp_auto_load = [dict[@(OBF("esp_auto_load"))] boolValue];
    if (dict[@(OBF("esp_screenshot_safe"))]) esp_screenshot_safe = [dict[@(OBF("esp_screenshot_safe"))] boolValue];
    if (dict[@(OBF("hit_sound"))]) esp_hit_sound_enabled = [dict[@(OBF("hit_sound"))] boolValue];
    if (dict[@(OBF("skeleton_en"))])   esp_skeleton_enabled = [dict[@(OBF("skeleton_en"))]   boolValue];
    if (dict[@(OBF("skeleton_head"))]) esp_skeleton_head    = [dict[@(OBF("skeleton_head"))] boolValue];
    if (dict[@(OBF("menu_effect"))]) esp_menu_effect = [dict[@(OBF("menu_effect"))] intValue];
    if (dict[@(OBF("preview_window"))]) esp_preview_window = [dict[@(OBF("preview_window"))] boolValue];
    if (dict[@(OBF("update_rate"))]) esp_update_rate = [dict[@(OBF("update_rate"))] intValue];

    // Colors
    if (dict[@"menu_r"]) g_menuR = [dict[@"menu_r"] floatValue];
    if (dict[@"menu_g"]) g_menuG = [dict[@"menu_g"] floatValue];
    if (dict[@"menu_b"]) g_menuB = [dict[@"menu_b"] floatValue];
    if (dict[@"text_r"]) g_textR = [dict[@"text_r"] floatValue];
    if (dict[@"text_g"]) g_textG = [dict[@"text_g"] floatValue];
    if (dict[@"text_b"]) g_textB = [dict[@"text_b"] floatValue];
    if (dict[@"box_r"])  esp_box_r  = [dict[@"box_r"]  floatValue];
    if (dict[@"box_g"])  esp_box_g  = [dict[@"box_g"]  floatValue];
    if (dict[@"box_b"])  esp_box_b  = [dict[@"box_b"]  floatValue];
    if (dict[@"box_thick"])   esp_box_thickness   = [dict[@"box_thick"]   floatValue];
    if (dict[@"box3d_thick"]) esp_box3d_thickness = [dict[@"box3d_thick"] floatValue];
    if (dict[@"skel_thick"])  esp_skeleton_thickness = [dict[@"skel_thick"] floatValue];
    if (dict[@"skel_r"]) esp_skeleton_r = [dict[@"skel_r"] floatValue];
    if (dict[@"skel_g"]) esp_skeleton_g = [dict[@"skel_g"] floatValue];
    if (dict[@"skel_b"]) esp_skeleton_b = [dict[@"skel_b"] floatValue];
    if (dict[@"line_r"]) esp_line_r = [dict[@"line_r"] floatValue];
    if (dict[@"line_g"]) esp_line_g = [dict[@"line_g"] floatValue];
    if (dict[@"line_b"]) esp_line_b = [dict[@"line_b"] floatValue];
    if (dict[@"name_r"]) esp_name_r = [dict[@"name_r"] floatValue];
    if (dict[@"name_g"]) esp_name_g = [dict[@"name_g"] floatValue];
    if (dict[@"name_b"]) esp_name_b = [dict[@"name_b"] floatValue];
    if (dict[@"health_r"]) esp_health_r = [dict[@"health_r"] floatValue];
    if (dict[@"health_g"]) esp_health_g = [dict[@"health_g"] floatValue];
    if (dict[@"health_b"]) esp_health_b = [dict[@"health_b"] floatValue];
    if (dict[@"weapon_r"]) esp_weapon_r = [dict[@"weapon_r"] floatValue];
    if (dict[@"weapon_g"]) esp_weapon_g = [dict[@"weapon_g"] floatValue];
    if (dict[@"weapon_b"]) esp_weapon_b = [dict[@"weapon_b"] floatValue];
    if (dict[@"fov_r"]) esp_fov_r = [dict[@"fov_r"] floatValue];
    if (dict[@"fov_g"]) esp_fov_g = [dict[@"fov_g"] floatValue];
    if (dict[@"fov_b"]) esp_fov_b = [dict[@"fov_b"] floatValue];
    if (dict[@"arr_en"])   esp_arrows_enabled = [dict[@"arr_en"]   boolValue];
    if (dict[@"arr_ol"])   esp_arrows_outline = [dict[@"arr_ol"]   boolValue];
    if (dict[@"arr_marg"]) esp_arrows_margin = [dict[@"arr_marg"] floatValue];
    if (dict[@"arr_size"]) esp_arrows_size   = [dict[@"arr_size"] floatValue];
    if (dict[@"ar"])       esp_arrows_r       = [dict[@"ar"]       floatValue];
    if (dict[@"ag"])       esp_arrows_g       = [dict[@"ag"]       floatValue];
    if (dict[@"ab"])       esp_arrows_b       = [dict[@"ab"]       floatValue];
}

void cfg_delete(NSString *name) {
    if (name.length == 0) return;
    NSString *fileName = [NSString stringWithFormat:@"wxr_conf_%@.confing", name];
    NSString *path = [cfg_get_dir() stringByAppendingPathComponent:fileName];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

