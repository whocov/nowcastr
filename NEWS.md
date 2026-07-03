<!-- Major.Minor.Patch <.dev> -->

<!-- 
# nowcastr x.x.x
* [feature] iterative last value convergence
* [feature] horizontal gap filling
* [feature] CI range propagation from fitted-model 
* [feature] work with tidytable
-->


# nowcastr 0.2.1
- [feature] new theme for plots
- [refactor] simplify evaluation results columns
- [refactor] remove 2 internal plot functions from exports
- [bugfix] r squared calculation with na.rm in plot delays <!-- added `rm.na=T` in ss_tot calculation  -->
- [refactor] Add good fit/bad fit color to delays and results plots.

# nowcastr 0.2.0
- [feature] accuracy evaluation function
- [feature] accuracy evaluation plots
- [feature] shiny to visualize model results 
- [bugfix] resolve github installs namespace conflicts

# nowcastr 0.1.1
- [bugfix] ensure S7 methods are registered before S3 dispatch happens

# nowcastr 0.1.0
- [feature] base model-free nowcast
- [feature] model-fitting
- [feature] plot method for raw data: triangle
- [feature] plot method for raw data: millipede
- [feature] plot method for delays
- [feature] plot method for nowcast results
- [feature] S7 Object output and S7 plot method 
- [feature] utility function: retro-score analysis
- [feature] utility function: remove duplicated values
- [feature] utility function: future fill missing
- [feature] testing data generator
- [feature] testing and demo datasets

<!-- 
# nowcastr 0.0.1
- Project started in Jan 2024
-->
