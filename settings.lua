data:extend({{
    type = "int-setting",
    name = "gps_arrow-size",
    setting_type = "runtime-global",
    default_value = 5,
    minimum_value = 1,
    maximum_value = 15,
    order = "a1"
}, {
    type = "int-setting",
    name = "gps_arrow-offset",
    setting_type = "runtime-global",
    default_value = 20,
    minimum_value = 1,
    maximum_value = 50,
    order = "a1"
}, {
    type = "int-setting",
    name = "gps_destination-distance",
    setting_type = "runtime-global",
    default_value = 5,
    minimum_value = 2,
    maximum_value = 15,
    order = "a1"
}, {
    type = "string-setting",
    name = "gps_tag-name",
    setting_type = "runtime-global",
    default_value = 'gps-destination',
    order = "a1"
}, {
    type = "string-setting",
    name = "gps_arrow-sprite",
    setting_type = "runtime-global",
    default_value = "Navigation",
    allowed_values = {"Navigation", "Vanilla", "Better"}
}})
