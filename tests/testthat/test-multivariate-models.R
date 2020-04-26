library(dplyr, warn.conflicts = FALSE, quietly = TRUE)
library(tidyr, quietly = TRUE)
library(nlme)

data(bdf, package = "mlmRev")

bdf_long <-
  bdf %>%
  filter(schoolNR %in% levels(schoolNR)[1:12]) %>%
  droplevels() %>%
  pivot_longer(cols = c(IQ.verb, IQ.perf, aritPRET),
               names_to = "measure",
               values_to = "score") %>%
  select(schoolNR, pupilNR, sex, Minority, measure, score) %>%
  arrange(schoolNR, pupilNR, measure)

bdf_MVML <- lme(score ~ 0 + measure,
                random = ~ 1| schoolNR / pupilNR,
                corr = corSymm(form = ~ 1 | schoolNR / pupilNR),
                weights = varIdent(form = ~ 1 | measure),
                data = bdf_long)

# mod <- bdf_MVML
# struct <- mod$modelStruct$corStruct

# introduce random missing to bdf_long
set.seed(20200311)
bdf_long$school_id <- bdf_long$schoolNR
levels(bdf_long$school_id) <- LETTERS[1:nlevels(bdf_long$school_id)]

bdf_long_wm <-
  bdf_long %>%
  mutate(
    row_index = rbinom(n = n(), size = 1, prob = 0.9),
    score = if_else(row_index == 1, score, as.numeric(NA)),
    measure_id = as.integer(factor(measure))
  ) %>%
  filter(!is.na(score)) %>%
  select(-row_index) %>%
  arrange(schoolNR, pupilNR, measure_id)

bdf_long_shuff <-
  sample_frac(bdf_long_wm, 1) %>%
  mutate(row = row_number())

bdf_wm <- lme(score ~ 0 + measure,
              random = ~ 1| schoolNR / pupilNR,
              corr = corSymm(form = ~ measure_id | schoolNR / pupilNR),
              weights = varIdent(form = ~ 1 | measure_id),
              data = bdf_long_wm,
              control=lmeControl(msMaxIter = 100, apVar = FALSE, returnObject = TRUE))

bdf_wm_shuff <- lme(score ~ 0 + measure,
                    random = ~ 1| schoolNR / pupilNR,
                    corr = corSymm(form = ~ measure_id | schoolNR / pupilNR),
                    weights = varIdent(form = ~ 1 | measure_id),
                    data = bdf_long_shuff,
                    control=lmeControl(msMaxIter = 100, apVar = FALSE, returnObject = TRUE))

bdf_wm_id <- lme(score ~ 0 + measure,
                  random = ~ 1| school_id / pupilNR,
                  corr = corSymm(form = ~ measure_id | school_id / pupilNR),
                  weights = varIdent(form = ~ 1 | measure_id),
                  data = bdf_long_shuff,
                  control=lmeControl(msMaxIter = 100, apVar = FALSE, returnObject = TRUE))


test_that("targetVariance() works with multivariate models.", {
  test_Sigma_mats(bdf_MVML, bdf_long$schoolNR)
  test_Sigma_mats(bdf_wm, bdf_long_wm$schoolNR)
  test_Sigma_mats(bdf_wm_id, bdf_long_shuff$school_id)
  test_Sigma_mats(bdf_wm_shuff, bdf_long_shuff$school_id)
})

test_that("Derivative matrices are of correct dimension with multivariate models.", {
  test_deriv_dims(bdf_MVML)
  test_deriv_dims(bdf_wm)
  test_deriv_dims(bdf_wm_id)
  test_deriv_dims(bdf_wm_shuff)
})

test_that("Information matrices work with FIML too.", {
  test_with_FIML(bdf_MVML)
  test_with_FIML(bdf_wm)
  test_with_FIML(bdf_wm_id)
  test_with_FIML(bdf_wm_shuff)
})

test_that("New REML calculations work.", {
  check_REML2(bdf_MVML)
  check_REML2(bdf_wm)
  check_REML2(bdf_wm_id)
  check_REML2(bdf_wm_shuff)
})