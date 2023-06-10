# GRPH Mangling scheme
## For IRGen

### Default mangling

In the following names, replace parenthesized expression with the size in bytes of the value, in ascii base 10 digits, followed by the value

Function calls: `_GF(namespace)(function_name)`
 - Ex: `_GF4none5hello`

Global variables: `_GV(namespace)(variable_name)`

### C-Friendly Library mangling

Function calls: `grph_{namespace}_{function_name}`
 - Ex: `grph_none_hello`

Global variables: `grphv_global_{variable_name}`

Property getters: `grphp_{on_type}_{property_name}_get`

Conversion casts: `grphas_{dest_type}`

Constructors: `grphc_{type}`

### Naming convention

Operators: `grphop_{operator_name}`

Value Witness Table function: `grphvwt_{action}_{generic_type}`

Reference type destructors: `grphd_{type}`

Graphics-rendering functions: `grphg_{name}`

Shape drawing functions: `grphg_draw_{name}`

Array actions: `grpharr_{action}`
