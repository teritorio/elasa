UPDATE
    directus_fields
SET
    options = '{"presets":[{"name":"$t:amenity","color":"#2A62AC"},{"name":"$t:catering","color":"#DB7900"},{"name":"$t:local_shop","color":"#009CB8"},{"name":"$t:craft","color":"#C58511"},{"name":"$t:culture","color":"#76009E"},{"name":"$t:culture_shopping","color":"#A04C97"},{"name":"$t:education","color":"#4076F6"},{"name":"$t:hosting","color":"#99163A"},{"name":"$t:leisure","color":"#00A757"},{"name":"$t:mobility","color":"#008ECF"},{"name":"$t:nature","color":"#8CC56F"},{"name":"$t:products","color":"#F25C05"},{"name":"$t:public_landmark","color":"#1D1D1B"},{"name":"$t:remarkable","color":"#E50980"},{"name":"$t:safety","color":"#E42224"},{"name":"$t:services","color":"#2A62AC"},{"name":"$t:services_shopping","color":"#4E7AB5"},{"name":"$t:shopping","color":"#808080"},{"name":"$t:social_services","color":"#006660"}]}'::json
WHERE
    id IN (78, 79)
;
