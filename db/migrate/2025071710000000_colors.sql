UPDATE
    directus_fields
SET
    options = '{"presets":[{"name":"$t:amenity","color":"#2A62AC"},{"name":"$t:catering","color":"#CC4C16"},{"name":"$t:local_shop","color":"#278096"},{"name":"$t:craft","color":"#996E0A"},{"name":"$t:culture","color":"#76009E"},{"name":"$t:culture_shopping","color":"#A04C97"},{"name":"$t:education","color":"#3366FF"},{"name":"$t:hosting","color":"#99163A"},{"name":"$t:leisure","color":"#008A1E"},{"name":"$t:mobility","color":"#007DB8"},{"name":"$t:nature","color":"#006B31"},{"name":"$t:products","color":"#BD533C"},{"name":"$t:public_landmark","color":"#000000"},{"name":"$t:remarkable","color":"#C02469"},{"name":"$t:safety","color":"#E42224"},{"name":"$t:services","color":"#2A62AC"},{"name":"$t:services_shopping","color":"#5173B7"},{"name":"$t:shopping","color":"#767676"},{"name":"$t:social_services","color":"#006660"}]}'::json
WHERE
    id IN (78, 79)
;
