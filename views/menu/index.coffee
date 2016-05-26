# PROTOCAL FOR MENUTREE
#   All menu properties will be accumulated to its children except sub.
#   See accumulateMenu
# MENU := 
#   title:
#       The text shown in the dropdown input in its parent
#   value:
#       If exists, this item is a terminate and will return this as raw_value.
#   sub:
#       {MENU_ID: MENUITEM}
#       If exists, this item is a dropdown input.
#       Otherwise, this item is a text input.
#       Use the form of '_abcd' as MENU_ID to distinguish it from menu properties.
#   applyEnabledFunc:
#       (path, raw_value) -> Boolean
#       Return true if the "Apply" button is enabled
#   preprocess:
#       (path, raw_value) -> pre_value
#       Change the raw input to make it easier to store and process afterwards.
#       Will be called the first time adding this rule.
#       Result must be JSONisable.
#   testError:
#       (path, pre_value) -> String | undefined
#       The raw_value is valid if the input return undefined.
#       Otherwise, return the error prompt.
#       Like applyEnabledFunc, but more of runtime check.
#   porting:
#       (path, pre_value) -> {path: PATH, value: VALUE} | null
#       Called after reading from file. Change the filter from older format
#       to the latest one. The bookmark record is changed accordingly afterwards.
#       Return the original {path, value} even if nothing needs porting.
#       Return null if unable to port.
#   postprocess:
#       (path, pre_value) -> post_value
#       Change the value returned by preprocess to make easier to process.
#       Will be called every time adding this rule (e.g. at start up).
#       Result does not have to be JSONisable.
#   func:
#       (path, post_value, record) -> Boolean
#       Rule filtering function. Return true if the record satisfies the rule
#   textFunc:
#       (path, post_value) -> String
#       The text interpretation to be displayed in rule list.

module.exports = 
  '_root': 
     # Default
     func: -> true
     applyEnabledFunc: (path, value) ->
       value? && value.length != 0
     porting: (path, value) -> {path, value}
     sub:
       '_map': require './map'
       '_ship': require './ship'
       '_time': require './time'
