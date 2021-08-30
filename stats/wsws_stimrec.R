library(tidyverse)
library(lme4)
library(car)
library(emmeans)
library(performance)
library(ordinal)
library(RVAideMemoire)

# global settings
options(contrasts = c("contr.sum", "contr.poly"))

# import data
dat <- read.csv("wsws_stimRec.csv", header = TRUE)

# create factors
dat <- dat %>% 
  select( !starts_with(c("RecOri", "Diff")) ) %>%
  select( !ends_with(c("Chunk2", "Chunk3")) ) %>%
  mutate(SubID = as.factor(SubID),
         Clarity = as.ordered(Clarity)
  )


# create wide df from Chunk 1 reconstruction data only
dat.w <- dat %>% 
  select(-Rec, -Band) %>%
  pivot_wider(names_from = Rep, 
            values_from = c(Rec_Chunk1, Clarity) ) %>%
  rename(Rec1 = Rec_Chunk1_1, 
         Rec2 = Rec_Chunk1_2)



### model subjective clarity ratings
c1 <- clmm(Clarity_2 ~ Clarity_1 + Type +
             (1+Type|SubID) + (1|CodeStim),
           data = dat.w)

c2 <- clmm(Clarity_2 ~ Clarity_1 + Type + Cond + 
             (1+Type+Cond|SubID) + (1|CodeStim),
           data = dat.w)	

c3 <- clmm(Clarity_2 ~ Clarity_1 + Type * Cond + 
             (1+Type*Cond|SubID) + (1|CodeStim),
           data = dat.w)	

# compare models
anova(c1, c2, c3)

# anova table for winning model
Anova.clmm(c2, type=2)

# contrasts for winning model
pairs(emmeans(c2, ~Type))
pairs(emmeans(c2, ~Cond))



### model stimulus reconstruction scores
r1 <- lmer(Rec2 ~ Rec1 + Type +
             (1+Type|SubID) + (1|CodeStim), 
           data = dat.w, REML = TRUE, control=lmerControl(optimizer="bobyqa"))

r2 <- lmer(Rec2 ~ Rec1 + Type + Cond +
             (1+Type|SubID) + (1|CodeStim),
           data = dat.w, REML = TRUE, control=lmerControl(optimizer="bobyqa"))

r3 <- lmer(Rec2 ~ Rec1 + Type * Cond +
             (1+Type|SubID) + (1|CodeStim),
           data = dat.w, REML = TRUE, control=lmerControl(optimizer="bobyqa"))

r4 <- lmer(Rec2 ~ Rec1 * Type * Cond +
             (1+Type|SubID) + (1|CodeStim),
           data = dat.w, REML = TRUE, control=lmerControl(optimizer="bobyqa"))

# compare models
anova(r1,r2,r3,r4)

# anova table for winning model
Anova(r2)

# contrasts for winning model
pairs(emmeans(r2, ~Type))
pairs(emmeans(r2, ~Cond))



### introduce stimulus reconstruction score into clarity model
cr0 <- c2

cr1 <- clmm(Clarity_2 ~ Clarity_1 + Type + Cond + Rec2 + 
              (1+Type+Cond|SubID) + (1|CodeStim),      
            data = dat.w)

cr2 <- clmm(Clarity_2 ~ Clarity_1 + Type*Cond*Rec2 + 
              (1+Type*Cond|SubID) + (1|CodeStim),
            data = dat.w)

# compare models
anova(cr0,cr1,cr2)
