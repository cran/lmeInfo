library(nlme)

skip_if_not_installed("scdhlm")

# Two-level model
data(Laski, package = "scdhlm")

Laski_fx_sigma <- lme(fixed = outcome ~ treatment,
                      random = ~ treatment | case,
                      control = lmeControl(sigma = 2),
                      data = Laski)

# attr(Laski_fx_sigma$modelStruct, "fixedSigma") # Indicating whether sigma is fixed or not
# Fisher_info(Laski_fx_sigma, type = "averaged")

# Three-level model
data(Thiemann2001, package = "scdhlm")

Thiemann2001_fx_sigma <- lme(fixed = outcome ~ treatment,
                             random = ~ 1 | case/series,
                             correlation = corAR1(0, ~ time | case/series),
                             control = lmeControl(sigma = 1),
                             data = Thiemann2001)

# attr(Thiemann2001_fx_sigma$modelStruct, "fixedSigma")
# Fisher_info(Thiemann2001_fx_sigma, type = "expected")

test_that("targetVariance() works with models when sigma is fixed.", {
  test_Sigma_mats(Laski_fx_sigma, Laski$case)
  test_Sigma_mats(Thiemann2001_fx_sigma, Thiemann2001$case)
})

test_that("Derivative matrices are of correct dimension with models when sigma is fixed.", {
  test_deriv_dims(Laski_fx_sigma)
  test_deriv_dims(Thiemann2001_fx_sigma)
})

test_that("Information matrices work with FIML too when sigma is fixed.", {
  test_with_FIML(Laski_fx_sigma)
  test_with_FIML(Thiemann2001_fx_sigma)
})

test_that("Results do not depend on order of data.", {
  test_after_shuffling(Laski_fx_sigma, seed = 20)
  test_after_shuffling(Thiemann2001_fx_sigma, seed = 20)
})

test_that("Info matrices work with dropped observations.", {
  test_after_deleting(Laski_fx_sigma, seed = 30)
  test_after_deleting(Thiemann2001_fx_sigma, seed = 30)
})

test_that("New REML calculations work.", {

  check_REML2(Laski_fx_sigma)
  check_REML2(Thiemann2001_fx_sigma)
})
