UPDATE directus_fields SET options = '{"presets":[{"name":"$t:amenity","color":"#2A62AC"},{"name":"$t:catering","color":"#DB7900"},{"name":"$t:local_shop","color":"#009CB8"},{"name":"$t:craft","color":"#C58511"},{"name":"$t:culture","color":"#76009E"},{"name":"$t:culture_shopping","color":"#A04C97"},{"name":"$t:education","color":"#4076F6"},{"name":"$t:hosting","color":"#99163A"},{"name":"$t:leisure","color":"#00A757"},{"name":"$t:mobility","color":"#008ECF"},{"name":"$t:nature","color":"#8CC56F"},{"name":"$t:products","color":"#F25C05"},{"name":"$t:public_landmark","color":"#1D1D1B"},{"name":"$t:remarkable","color":"#E50980"},{"name":"$t:safety","color":"#E42224"},{"name":"$t:services","color":"#2A62AC"},{"name":"$t:services_shopping","color":"#4E7AB5"},{"name":"$t:shopping","color":"#808080"},{"name":"$t:social_services","color":"#006660"}]}' WHERE id = 78;
UPDATE directus_fields SET options = '{"presets":[{"name":"$t:amenity","color":"#4E7AB5"},{"name":"$t:catering","color":"#DB7900"},{"name":"$t:local_shop","color":"#009CB8"},{"name":"$t:craft","color":"#C58511"},{"name":"$t:culture","color":"#A04C97"},{"name":"$t:culture_shopping","color":"#A04C97"},{"name":"$t:education","color":"#4076F6"},{"name":"$t:hosting","color":"#99163A"},{"name":"$t:leisure","color":"#00A757"},{"name":"$t:mobility","color":"#3B74B9"},{"name":"$t:nature","color":"#70B06A"},{"name":"$t:products","color":"#F25C05"},{"name":"$t:public_landmark","color":"#1D1D1B"},{"name":"$t:remarkable","color":"#E50980"},{"name":"$t:safety","color":"#E42224"},{"name":"$t:services","color":"#2A62AC"},{"name":"$t:services_shopping","color":"#2A62AC"},{"name":"$t:shopping","color":"#808080"},{"name":"$t:social_services","color":"#006660"}]}' WHERE id = 79;

UPDATE menu_items SET color_fill = '#009cb8' WHERE color_fill ilike '#00b3cc';
UPDATE menu_items SET color_fill = '#4e7ab5' WHERE color_fill ilike '#7093c3';
UPDATE menu_items SET color_fill = '#a04c97' WHERE color_fill ilike '#a16cb3';
UPDATE menu_items SET color_fill = '#db7900' WHERE color_fill ilike '#f5b700';

UPDATE menu_items SET color_line = '#009cb8' WHERE color_line ilike '#00a0c4';
UPDATE menu_items SET color_line = '#4e7ab5' WHERE color_line ilike '#2a62ac';
UPDATE menu_items SET color_line = '#a04c97' WHERE color_line ilike '#76009e';
UPDATE menu_items SET color_line = '#db7900' WHERE color_line ilike '#f09007';
