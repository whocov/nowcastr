# ensure S7 methods are registered before S3 dispatch happens
.onLoad <- function(libname, pkgname) {
  S7::methods_register()
}
