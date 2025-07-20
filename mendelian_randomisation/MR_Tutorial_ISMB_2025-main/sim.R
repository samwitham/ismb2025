# MR Simulations
# Converted from sim.Rmd to R script
# to run in vscode, go to terminal, start R and then: shiny::runApp("sim.R", port = 8080, launch.browser = FALSE)

# --- Libraries ---
library(dplyr)
library(stats)
library(metafor)
library(ggplot2)
library(shinyWidgets)
library(tidyr)
library(shiny)

# --- Simulation Parameters ---
J <- 20 # Number of SNPs to simulate
N <- 1000 # Individuals in exposure sample
MAF <- 0.3 # Minor Allele Frequency
MEAN_GAMMA <- 3 # Mean of gamma (SNP effects on exposure)
BETA <- 0.05 # True causal effect of X on Y
P_PLEIO <- 0.3 # Proportion of pleiotropic SNPs

# Function to estimate SNP coefficients using OLS
estimate_coefficients <- function(G, trait) {
  results_list <- list()
  for (j in 1:ncol(G)) {
    df_snp <- data.frame(snp = G[, j], trait = trait)
    model <- lm(trait ~ snp, data = df_snp)
    c <- coef(model)["snp"]
    std_err <- summary(model)$coefficients["snp", "Std. Error"]
    p_value <- summary(model)$coefficients["snp", "Pr(>|t|)"]
    results_list[[j]] <- data.frame(
      snp_index = j - 1,
      coef = c,
      std_err = std_err,
      p_value = p_value
    )
  }
  return(do.call(rbind, results_list))
}

# Function to generate individual-level data
generate_individual <- function(
    beta = BETA,
    J = J,
    N = N,
    maf = MAF,
    mean_gamma = MEAN_GAMMA,
    mean_alpha = 0,
    is_pleiotropy = FALSE,
    is_inside = TRUE,
    pleio_proportion = P_PLEIO,
    seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  if (is_pleiotropy) {
    alphas <- runif(J, -0.2, 0.2) + mean_alpha
  } else {
    alphas <- rep(0, J)
  }
  if (is_inside) {
    phis <- rep(0, J)
  } else {
    phis <- runif(J, 0, 0.5)
  }
  pis <- rbinom(J, 1, pleio_proportion)
  gammas <- runif(J, 0.5, 2 * MEAN_GAMMA - 0.5)
  G1 <- matrix(rbinom(N * J, 2, maf), nrow = N, ncol = J)
  G2 <- matrix(rbinom(N * J, 2, maf), nrow = N, ncol = J)
  eps_scale <- 2
  epsilon_C <- rnorm(N, 0, eps_scale)
  epsilon_X <- rnorm(N, 0, eps_scale)
  epsilon_Y <- rnorm(N, 0, eps_scale)
  C1 <- G1 %*% phis + epsilon_C
  C2 <- G2 %*% phis + epsilon_C
  X1 <- G1 %*% gammas + C1 + epsilon_X
  X2 <- G2 %*% gammas + C2 + epsilon_X
  Y <- beta * X2 + G2 %*% (alphas * pis) + C2 + epsilon_Y
  return(list(
    G1 = G1,
    G2 = G2,
    C1 = C1,
    C2 = C2,
    X1 = as.vector(X1),
    X2 = as.vector(X2),
    Y = as.vector(Y)
  ))
}

# Function to run the full two-sample MR simulation
simulate_model <- function(
    beta = BETA,
    J = J,
    N = N,
    maf = MAF,
    mean_gamma = MEAN_GAMMA,
    mean_alpha = 0,
    is_pleiotropy = FALSE,
    is_inside = TRUE,
    pleio_proportion = P_PLEIO,
    seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  data <- generate_individual(
    beta = beta,
    J = J,
    N = N,
    maf = maf,
    mean_gamma = mean_gamma,
    mean_alpha = mean_alpha,
    is_pleiotropy = is_pleiotropy,
    is_inside = is_inside,
    pleio_proportion = pleio_proportion,
    seed = seed
  )
  gamma_hat_df <- estimate_coefficients(data$G1, data$X1)
  Gamma_hat_df <- estimate_coefficients(data$G2, data$Y)
  gamma_hat <- gamma_hat_df$coef
  Gamma_hat <- Gamma_hat_df$coef
  gamma_se <- gamma_hat_df$std_err
  Gamma_se <- Gamma_hat_df$std_err
  gamma_p <- gamma_hat_df$p_value
  Gamma_p <- Gamma_hat_df$p_value
  df_sim <- data.frame(
    gamma_hat = gamma_hat,
    Gamma_hat = Gamma_hat,
    gamma_se = gamma_se,
    Gamma_se = Gamma_se,
    gamma_p = gamma_p,
    Gamma_p = Gamma_p,
    weight = 1 / (Gamma_se^2),
    wald_ratio = Gamma_hat / gamma_hat
  ) %>%
    arrange(gamma_hat)
  return(df_sim)
}

# Compute IVW estimate
compute_ivw <- function(df_reg) {
  wls_model <- lm(Gamma_hat ~ 0 + gamma_hat, data = df_reg, weights = weight)
  beta_ivw <- coef(wls_model)["gamma_hat"]
  return(list(beta_ivw = beta_ivw, wls_model = wls_model))
}

# Compute Egger estimate
compute_egger <- function(df_reg) {
  wls_model <- lm(Gamma_hat ~ gamma_hat, data = df_reg, weights = weight)
  alpha <- coef(wls_model)["(Intercept)"]
  beta <- coef(wls_model)["gamma_hat"]
  return(list(alpha = alpha, beta = beta, wls_model = wls_model))
}

# Example: Run a simulation and show head of results
data <- simulate_model(
  beta = BETA,
  J = 100,
  N = 5000,
  maf = MAF,
  mean_gamma = MEAN_GAMMA,
  mean_alpha = 0,
  is_pleiotropy = FALSE,
  is_inside = TRUE,
  pleio_proportion = P_PLEIO,
  seed = NULL
)
print(head(data))

# Example: IVW estimate (No pleiotropy)
df_sim_np <- simulate_model(
  beta = 0.05,
  is_pleiotropy = FALSE,
  is_inside = TRUE,
  J = 50,
  N = 5000,
  mean_alpha = 0,
  pleio_proportion = 0
)
ivw_result_np <- compute_ivw(df_sim_np)
beta_ivw_np <- ivw_result_np$beta_ivw
df_sim_np$ivw <- df_sim_np$gamma_hat * beta_ivw_np
df_sim_np$true <- df_sim_np$gamma_hat * 0.05

# Example: IVW estimate (Balanced pleiotropy)
df_sim_bp <- simulate_model(
  beta = 0.05,
  mean_alpha = 0,
  is_pleiotropy = TRUE,
  is_inside = TRUE,
  pleio_proportion = 1,
  J = 50,
  N = 5000
)
ivw_result_bp <- compute_ivw(df_sim_bp)
beta_ivw_bp <- ivw_result_bp$beta_ivw
df_sim_bp$ivw <- df_sim_bp$gamma_hat * beta_ivw_bp
df_sim_bp$true <- df_sim_bp$gamma_hat * 0.05

# Example: Funnel plot data
df_sim_fp <- simulate_model(
  beta = 0.05,
  mean_alpha = 0,
  is_pleiotropy = TRUE,
  is_inside = TRUE,
  pleio_proportion = 0.0,
  J = 50,
  N = 5000
)
ivw_result_fp <- compute_ivw(df_sim_fp)
beta_ivw_fp <- ivw_result_fp$beta_ivw

# Example: Egger regression (toggle InSIDE)
df_sim_egger <- simulate_model(
  beta = 0.05,
  mean_alpha = 0,
  is_pleiotropy = TRUE,
  is_inside = TRUE,
  pleio_proportion = 0.3,
  J = 50,
  N = 5000
)
ivw_result_egger <- compute_ivw(df_sim_egger)
egger_result_egger <- compute_egger(df_sim_egger)
df_sim_egger$ivw <- df_sim_egger$gamma_hat * ivw_result_egger$beta_ivw
df_sim_egger$egger <- egger_result_egger$alpha + egger_result_egger$beta * df_sim_egger$gamma_hat
df_sim_egger$true <- df_sim_egger$gamma_hat * 0.05

# Monte Carlo simulation results (requires mc_data.csv in data/ directory)
# df <- read.csv("data/mc_data.csv", stringsAsFactors = FALSE)
# print(head(df))

# The plotting and Shiny UI code from the Rmd is omitted in this script version.
# For full interactive exploration, use the original Rmd or a Shiny app.


ui <- fluidPage(
  titlePanel("MR Simulation Explorer (Full Rmd Version)"),
  tabsetPanel(
    # No pleiotropy tab
    tabPanel(
      "IVW: No Pleiotropy",
      sidebarLayout(
        sidebarPanel(
          sliderInput("beta_slider_np", "Beta:", min = 0.0, max = 0.5, value = 0.05, step = 0.01),
          sliderInput("J_slider_np", "J (SNPs):", min = 10, max = 200, value = 50, step = 1),
          sliderInput("N_slider_np", "N (Sample Size):", min = 250, max = 10000, value = 5000, step = 250),
          actionButton("run_button_np", "Run Simulation (No Pleiotropy)")
        ),
        mainPanel(
          plotOutput("plot_np", width = "800px", height = "600px")
        )
      )
    ),
    # Balanced pleiotropy tab
    tabPanel(
      "IVW: Balanced Pleiotropy",
      sidebarLayout(
        sidebarPanel(
          sliderInput("beta_slider_bp", "Beta:", min = 0.0, max = 0.5, value = 0.05, step = 0.01),
          sliderInput("J_slider_bp", "J (SNPs):", min = 10, max = 200, value = 50, step = 1),
          sliderInput("N_slider_bp", "N (Sample Size):", min = 250, max = 10000, value = 5000, step = 250),
          sliderInput("mean_alpha_slider_bp", "Mean alpha:", min = 0, max = 3, value = 0, step = 0.1),
          actionButton("run_button_bp", "Run Simulation (Balanced Pleiotropy)")
        ),
        mainPanel(
          plotOutput("plot_bp", width = "800px", height = "600px")
        )
      )
    ),
    # Funnel plot tab
    tabPanel(
      "Funnel Plot",
      sidebarLayout(
        sidebarPanel(
          sliderInput("beta_slider_fp", "Beta:", min = 0.0, max = 0.5, value = 0.05, step = 0.01),
          sliderInput("J_slider_fp", "J (SNPs):", min = 10, max = 200, value = 50, step = 1),
          sliderInput("N_slider_fp", "N (Sample Size):", min = 250, max = 10000, value = 5000, step = 250),
          sliderInput("mean_alpha_slider_fp", "Mean Alpha:", min = 0.0, max = 2.0, value = 0.0, step = 0.1),
          sliderInput("pleio_proportion_slider_fp", "Pleiotropic Proportion:", min = 0.0, max = 1.0, value = 0.0, step = 0.01),
          actionButton("run_button_fp", "Run Simulation (Funnel Plot)")
        ),
        mainPanel(
          plotOutput("plot_fp", width = "800px", height = "800px")
        )
      )
    ),
    # Egger regression tab
    tabPanel(
      "Egger Regression (InSIDE Toggle)",
      sidebarLayout(
        sidebarPanel(
          sliderInput("beta_slider_egger_inside", "Beta:", min = 0.0, max = 0.5, value = 0.05, step = 0.01),
          sliderInput("J_slider_egger_inside", "J (SNPs):", min = 10, max = 200, value = 50, step = 1),
          sliderInput("N_slider_egger_inside", "N (Sample Size):", min = 250, max = 10000, value = 5000, step = 250),
          sliderInput("mean_alpha_slider_egger_inside", "Mean Alpha:", min = 0.0, max = 2.0, value = 0.0, step = 0.1),
          sliderInput("pleio_proportion_slider_egger_inside", "Pleiotropic Proportion:", min = 0.0, max = 1.0, value = 0.3, step = 0.01),
          shinyWidgets::switchInput("is_inside_toggle_egger", "Assume InSIDE", value = TRUE, onStatus = "success", offStatus = "danger", onLabel = "Yes", offLabel = "No"),
          actionButton("run_button_egger_inside", "Run Simulation (Toggle InSIDE)")
        ),
        mainPanel(
          plotOutput("plot_egger_inside", width = "800px", height = "600px")
        )
      )
    ),
    # Monte Carlo simulation tab
    tabPanel(
      "Monte Carlo: Beta Bias",
      sidebarLayout(
        sidebarPanel(
          uiOutput("true_beta_selector_ui")
        ),
        mainPanel(
          plotOutput("plot_mc_bias", width = "800px", height = "800px")
        )
      )
    ),
    tabPanel(
      "Monte Carlo: Error Rates",
      sidebarLayout(
        sidebarPanel(
          uiOutput("error_beta_selector_ui")
        ),
        mainPanel(
          plotOutput("plot_mc_error", width = "800px", height = "800px")
        )
      )
    )
  )
)

server <- function(input, output, session) {
  # No pleiotropy
  reactive_plot_data_np <- eventReactive(input$run_button_np,
    {
      current_beta <- input$beta_slider_np
      current_J <- input$J_slider_np
      current_N <- input$N_slider_np
      df_sim <- simulate_model(
        beta = current_beta,
        is_pleiotropy = FALSE,
        is_inside = TRUE,
        J = current_J,
        N = current_N,
        mean_alpha = 0,
        pleio_proportion = 0
      )
      ivw_result <- compute_ivw(df_sim)
      beta_ivw <- ivw_result$beta_ivw
      df_sim$ivw <- df_sim$gamma_hat * beta_ivw
      df_sim$true <- df_sim$gamma_hat * current_beta
      df_sim
    },
    ignoreNULL = FALSE
  )
  output$plot_np <- renderPlot({
    df_plot <- reactive_plot_data_np()
    ggplot(df_plot, aes(x = gamma_hat, y = Gamma_hat)) +
      geom_point(aes(size = weight), alpha = 0.6) +
      geom_line(aes(y = ivw, color = "IVW Regression")) +
      geom_line(aes(y = true, color = "True Effect"), linetype = "dashed") +
      labs(
        title = "Scatter plot of SNP Effects (No Pleiotropy)",
        x = "SNP-exposure effect (gamma_hat)",
        y = "SNP-outcome effect (Gamma_hat)"
      ) +
      scale_color_manual(
        name = "Line Type",
        values = c("IVW Regression" = "orange", "True Effect" = "black")
      ) +
      theme_minimal() +
      theme(
        legend.position = "right",
        legend.text = element_text(size = 18),
        legend.title = element_text(size = 18, face = "bold"),
        axis.title = element_text(size = 18),
        plot.title = element_text(hjust = 0.5, face = "bold", size = 16)
      )
  })

  # Balanced pleiotropy
  reactive_plot_data_bp <- eventReactive(input$run_button_bp,
    {
      current_beta <- input$beta_slider_bp
      current_J <- input$J_slider_bp
      current_N <- input$N_slider_bp
      current_mean_alpha <- input$mean_alpha_slider_bp
      df_sim <- simulate_model(
        beta = current_beta,
        mean_alpha = current_mean_alpha,
        is_pleiotropy = TRUE,
        is_inside = TRUE,
        pleio_proportion = 1,
        J = current_J,
        N = current_N
      )
      ivw_result <- compute_ivw(df_sim)
      beta_ivw <- ivw_result$beta_ivw
      df_sim$ivw <- df_sim$gamma_hat * beta_ivw
      df_sim$true <- df_sim$gamma_hat * current_beta
      df_sim
    },
    ignoreNULL = FALSE
  )
  output$plot_bp <- renderPlot({
    df_plot <- reactive_plot_data_bp()
    ggplot(df_plot, aes(x = gamma_hat, y = Gamma_hat)) +
      geom_point(aes(size = weight), alpha = 0.6) +
      geom_line(aes(y = ivw, color = "IVW Regression")) +
      geom_line(aes(y = true, color = "True Effect"), linetype = "dashed") +
      labs(
        title = "Scatter plot of SNP Effects (Balanced Pleiotropy)",
        x = "SNP-exposure effect (gamma_hat)",
        y = "SNP-outcome effect (Gamma_hat)"
      ) +
      scale_color_manual(
        name = "Line Type",
        values = c("IVW Regression" = "orange", "True Effect" = "black")
      ) +
      theme_minimal() +
      theme(
        legend.position = "right",
        legend.text = element_text(size = 18),
        legend.title = element_text(size = 18, face = "bold"),
        axis.title = element_text(size = 18),
        plot.title = element_text(hjust = 0.5, face = "bold", size = 16)
      )
  })

  # Funnel plot
  reactive_funnel_plot_data <- eventReactive(input$run_button_fp,
    {
      current_beta <- input$beta_slider_fp
      current_J <- input$J_slider_fp
      current_N <- input$N_slider_fp
      current_mean_alpha <- input$mean_alpha_slider_fp
      current_pleio_proportion <- input$pleio_proportion_slider_fp
      df_sim <- simulate_model(
        beta = current_beta,
        mean_alpha = current_mean_alpha,
        is_pleiotropy = TRUE,
        is_inside = TRUE,
        pleio_proportion = current_pleio_proportion,
        J = current_J,
        N = current_N
      )
      ivw_result <- compute_ivw(df_sim)
      beta_ivw <- ivw_result$beta_ivw
      list(df_sim = df_sim, beta_ivw = beta_ivw, true_beta = current_beta)
    },
    ignoreNULL = FALSE
  )
  output$plot_fp <- renderPlot({
    plot_data <- reactive_funnel_plot_data()
    df_plot <- plot_data$df_sim
    beta_ivw <- plot_data$beta_ivw
    true_beta <- plot_data$true_beta
    p <- ggplot(df_plot, aes(x = wald_ratio, y = gamma_hat)) +
      geom_point(aes(size = weight), alpha = 0.6) +
      labs(
        title = "Funnel Plot",
        x = "Wald ratio (beta Hat)",
        y = "Instrument strength (gamma Hat)"
      ) +
      theme_minimal() +
      theme(
        legend.position = "right",
        legend.text = element_text(size = 18),
        legend.title = element_text(size = 18, face = "bold"),
        axis.title = element_text(size = 18),
        plot.title = element_text(hjust = 0.5, face = "bold", size = 16)
      )
    p <- p +
      geom_vline(aes(xintercept = true_beta, linetype = "True Beta", color = "True Beta"), size = 0.8) +
      geom_vline(aes(xintercept = beta_ivw, linetype = "IVW Estimate", color = "IVW Estimate"), size = 0.8)
    max_wald_ratio <- max(df_plot$wald_ratio, na.rm = TRUE)
    max_gamma_hat <- max(df_plot$gamma_hat, na.rm = TRUE)
    label_y_pos <- max_gamma_hat * 0.95
    if (label_y_pos < 0.1) label_y_pos <- 0.1
    p <- p +
      scale_linetype_manual(name = "Estimates", values = c("True Beta" = "dashed", "IVW Estimate" = "solid")) +
      scale_color_manual(name = "Estimates", values = c("True Beta" = "black", "IVW Estimate" = "orange")) +
      guides(size = "none", linetype = guide_legend(override.aes = list(size = 1)), color = guide_legend(override.aes = list(size = 1)))
    print(p)
  })

  # Egger regression (InSIDE toggle)
  reactive_plot_data_egger_inside <- eventReactive(input$run_button_egger_inside,
    {
      current_beta <- input$beta_slider_egger_inside
      current_J <- input$J_slider_egger_inside
      current_N <- input$N_slider_egger_inside
      current_mean_alpha <- input$mean_alpha_slider_egger_inside
      current_pleio_proportion <- input$pleio_proportion_slider_egger_inside
      current_is_inside <- input$is_inside_toggle_egger
      df_sim <- simulate_model(
        beta = current_beta,
        mean_alpha = current_mean_alpha,
        is_pleiotropy = TRUE,
        is_inside = current_is_inside,
        pleio_proportion = current_pleio_proportion,
        J = current_J,
        N = current_N
      )
      ivw_result <- compute_ivw(df_sim)
      egger_result <- compute_egger(df_sim)
      df_sim$ivw <- df_sim$gamma_hat * ivw_result$beta_ivw
      df_sim$egger <- egger_result$alpha + egger_result$beta * df_sim$gamma_hat
      df_sim$true <- df_sim$gamma_hat * current_beta
      df_sim
    },
    ignoreNULL = FALSE
  )
  output$plot_egger_inside <- renderPlot({
    df_plot <- reactive_plot_data_egger_inside()
    ggplot(df_plot, aes(x = gamma_hat, y = Gamma_hat)) +
      geom_point(aes(size = weight), alpha = 0.6) +
      geom_line(aes(y = ivw, color = "IVW Regression"), size = 0.8) +
      geom_line(aes(y = egger, color = "Egger Regression"), size = 0.8) +
      geom_line(aes(y = true, color = "True Effect"), linetype = "dashed", size = 0.8) +
      labs(
        title = "Scatter plot of SNP Effects (IVW & Egger, InSIDE Toggle)",
        x = "SNP-exposure effect (gamma_hat)",
        y = "SNP-outcome effect (Gamma_hat)"
      ) +
      scale_color_manual(
        name = "Line Type",
        values = c("IVW Regression" = "orange", "Egger Regression" = "steelblue", "True Effect" = "black")
      ) +
      scale_linetype_manual(
        name = "Line Type",
        values = c("IVW Regression" = "solid", "Egger Regression" = "solid", "True Effect" = "dashed"),
        guide = FALSE
      ) +
      guides(size = "none") +
      theme_minimal() +
      theme(
        legend.position = "right",
        legend.text = element_text(size = 18),
        legend.title = element_text(size = 18, face = "bold"),
        axis.title = element_text(size = 18),
        plot.title = element_text(hjust = 0.5, face = "bold", size = 16)
      )
  })

  # Monte Carlo simulation: bias
  mc_data <- reactive({
    read.csv("data/mc_data.csv", stringsAsFactors = FALSE)
  })
  output$true_beta_selector_ui <- renderUI({
    df <- mc_data()
    selectInput("true_beta_selector", "Select True Beta:", choices = unique(df$beta_true), selected = unique(df$beta_true)[1])
  })
  filteorange_data <- reactive({
    df <- mc_data()
    req(input$true_beta_selector)
    df %>%
      filter(beta_true == as.numeric(input$true_beta_selector)) %>%
      tidyr::pivot_longer(
        cols = c(beta_ivw, beta_egger),
        names_to = "Estimate_Type",
        values_to = "Beta_Estimate"
      ) %>%
      mutate(
        Estimate_Type = factor(Estimate_Type, levels = c("beta_ivw", "beta_egger"), labels = c("IVW Estimate", "Egger Estimate")),
        J = factor(J),
        pleio_scenario = factor(pleio_scenario, levels = c("a", "b", "c", "d"), labels = c("Scenario A: No Pleiotropy, InSIDE", "Scenario B: Balanced Pleiotropy, InSIDE", "Scenario C: Directional Pleiotropy, InSIDE", "Scenario D: Directional Pleiotropy, InSIDE Violated"))
      )
  })
  output$plot_mc_bias <- renderPlot({
    plot_df <- filteorange_data()
    true_beta_val <- as.numeric(input$true_beta_selector)
    fixed_ymin <- -0.1
    fixed_ymax <- 0.2
    ggplot(plot_df, aes(x = J, y = Beta_Estimate, fill = Estimate_Type)) +
      geom_boxplot(position = position_dodge(width = 0.8), outlier.shape = NA) +
      geom_hline(yintercept = true_beta_val, linetype = "dashed", color = "black", size = 0.8, aes(group = 1)) +
      facet_wrap(~pleio_scenario, scales = "fixed", ncol = 2) +
      labs(
        title = paste0("Beta Estimates by Scenario and J (True Beta = ", input$true_beta_selector, ")"),
        x = "Number of SNPs (J)",
        y = "Beta Estimate",
        fill = "Estimation Method"
      ) +
      scale_fill_manual(values = c("IVW Estimate" = "orange", "Egger Estimate" = "steelblue")) +
      scale_color_manual(name = "Reference", values = c("True Beta" = "black"), labels = c("True Beta")) +
      guides(color = guide_legend(override.aes = list(linetype = "dashed", shape = NA))) +
      theme_minimal() +
      theme(
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5, face = "bold", size = 16),
        strip.text = element_text(face = "bold", size = 14),
        axis.title = element_text(size = 12),
        axis.text = element_text(size = 10),
        legend.title = element_text(size = 12),
        legend.text = element_text(size = 10),
        panel.spacing = unit(1.5, "lines")
      ) +
      coord_cartesian(ylim = c(fixed_ymin, fixed_ymax))
  })

  # Monte Carlo simulation: error rates
  output$error_beta_selector_ui <- renderUI({
    df <- mc_data()
    selectInput("error_beta_selector", "Select True Beta for Error Rates:", choices = unique(df$beta_true), selected = unique(df$beta_true)[1])
  })
  error_rates_data <- reactive({
    df <- mc_data()
    req(input$error_beta_selector)
    current_beta_true <- as.numeric(input$error_beta_selector)
    alpha_level <- 0.05
    df_filtered_by_beta <- df %>% filter(beta_true == current_beta_true)
    scenario_descriptions <- c(
      "a" = "Scenario A: No Pleiotropy, InSIDE",
      "b" = "Scenario B: Balanced Pleiotropy, InSIDE",
      "c" = "Scenario C: Directional Pleiotropy, InSIDE",
      "d" = "Scenario D: Directional Pleiotropy, InSIDE Violated"
    )
    error_data_list <- list()
    for (scenario_key in names(scenario_descriptions)) {
      for (J_val in unique(df_filtered_by_beta$J)) {
        df_subset <- df_filtered_by_beta %>% filter(pleio_scenario == scenario_key, J == J_val)
        if (nrow(df_subset) > 0) {
          if (current_beta_true == 0) {
            error_ivw <- sum(df_subset$beta_ivw_pvalue < alpha_level) / nrow(df_subset)
            error_egger <- sum(df_subset$beta_egger_pvalue < alpha_level) / nrow(df_subset)
            error_type_label <- "Type 1 Error Rate"
            reference_value <- alpha_level
            reference_label <- paste0("Nominal b = ", alpha_level)
          } else {
            error_ivw <- sum(df_subset$beta_ivw_pvalue >= alpha_level) / nrow(df_subset)
            error_egger <- sum(df_subset$beta_egger_pvalue >= alpha_level) / nrow(df_subset)
            error_type_label <- "Type 2 Error Rate (1 - Power)"
            reference_value <- 0.2
            reference_label <- "20% Type 2 Error"
          }
          error_data_list[[length(error_data_list) + 1]] <- data.frame(
            pleio_scenario = scenario_key,
            J = J_val,
            method = "IVW",
            error_rate = error_ivw,
            error_type_label = error_type_label,
            reference_value = reference_value,
            reference_label = reference_label
          )
          error_data_list[[length(error_data_list) + 1]] <- data.frame(
            pleio_scenario = scenario_key,
            J = J_val,
            method = "Egger",
            error_rate = error_egger,
            error_type_label = error_type_label,
            reference_value = reference_value,
            reference_label = reference_label
          )
        }
      }
    }
    dplyr::bind_rows(error_data_list) %>%
      mutate(
        J = factor(J),
        method = factor(method, levels = c("IVW", "Egger")),
        pleio_scenario = factor(pleio_scenario, levels = names(scenario_descriptions), labels = scenario_descriptions)
      )
  })
  output$plot_mc_error <- renderPlot({
    plot_df <- error_rates_data()
    plot_title_suffix <- if (as.numeric(input$error_beta_selector) == 0) {
      "Type 1 Error Rates"
    } else {
      "Type 2 Error Rates"
    }
    ggplot(plot_df, aes(x = J, y = error_rate, fill = method)) +
      geom_col(position = position_dodge(width = 0.7), width = 0.6) +
      geom_hline(aes(yintercept = reference_value, linetype = reference_label), color = "orange", size = 0.8) +
      facet_wrap(~pleio_scenario, scales = "fixed", ncol = 2) +
      labs(
        title = paste0(plot_title_suffix, " by Number of Instruments (J) - b = ", input$error_beta_selector),
        x = "Number of Instruments (J)",
        y = unique(plot_df$error_type_label),
        fill = "Estimation Method"
      ) +
      scale_fill_manual(values = c("IVW" = "steelblue", "Egger" = "orange")) +
      scale_linetype_manual(name = "Reference Line", values = "dashed") +
      guides(linetype = guide_legend(order = 2), fill = guide_legend(order = 1)) +
      theme_minimal() +
      theme(
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5, face = "bold", size = 16),
        strip.text = element_text(face = "bold", size = 14),
        axis.title = element_text(size = 12),
        axis.text = element_text(size = 10),
        legend.title = element_text(size = 12),
        legend.text = element_text(size = 10),
        panel.spacing = unit(1.5, "lines")
      ) +
      coord_cartesian(ylim = c(0, 1)) +
      geom_text(aes(label = sprintf("%.3f", error_rate)), position = position_dodge(width = 0.7), vjust = -0.5, size = 3.5, color = "black")
  })
}

shinyApp(ui, server)
