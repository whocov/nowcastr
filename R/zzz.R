# ensure S7 methods are registered before S3 dispatch happens
# cf. https://rconsortium.github.io/S7/articles/packages.html
.onLoad <- function(libname, pkgname) {
  S7::methods_register()
}
