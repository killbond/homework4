library(ROCR)

# ������� ������ ������� �������� ����������� ���������� ������, �� �������
# ���������� �������� �������, � ����������� �� ���������� ������
#
# (integer) nfold - �������� ��������� � ����������� �� ���������� ������ ����������
#
# (string) method - ���������� ����� ���������� �������. � ������ 'number' - ���
# ����� ���������� ������ �� ���� �������, � ������ 'percent' - ��� �������
# ������ �� ���� �������, ���������� ��� ��������
getNparts <- function(nfold, method) {
  if(method != 'number') {
    nparts <- 100 %/% (100 - nfold)
  } else {
    nparts <- nfold
  }
  return(nparts)
}

# ������� ������ ������� �������� ���������� ���� ������� ������ ��
# ����� ��� �������� � ����������� ��������
#
# (integer) nfold - �������� ��������� � ����������� �� ���������� ������ ����������
#
# (integer) trainPart - ���������� ����� ����� �� ���� �������, ��������������� ���
# ����������� ��������
#
# (data frame) data - ������ ��� �������� ������
#
# (string) method - ���������� ����� ���������� �������. � ������ 'number' - ���
# ����� ���������� ������ �� ���� �������, � ������ 'percent' - ��� �������
# ������ �� ���� �������, ���������� ��� ��������
nfoldSubset <- function(nfold, trainPart, data, method = 'number') {
  
  # ��������� ����� ����� ������, � ����������� �� ������
  nparts <- getNparts(nfold, method)
  
  # ��������, ���������� �� ������ ����� ����������� �������
  if(nparts < trainPart) {
    return(FALSE)
  }
  
  # ��������� ���������� ����� � ����� ����� �������
  length <- nrow(data) %/% nparts
  
  # ���������, � ����� ����� ������� ���� �������
  # ��������� ����� ��� ����������� ��������
  if(trainPart != 1 && trainPart != nparts) {
    # ����������� ����� � ��������
    result <- list(
      # |xxx---xxx> ����� ��� ��������
      'learn' <- rbind(data[1:((trainPart - 1) * length),], data[(trainPart * length + 1):nrow(data),]),
      # |---xxx---> ����� ��� ����������� ��������
      'train' <- data[((trainPart - 1) * length + 1):((trainPart - 1) * length + length),]
    )
  } else {
    # ����������� ����� � ������ ���� � �����
    if(trainPart == 1) {
      result <- list(
        # |---xxxxxx> ����� ��� ��������
        'learn' = data[(length + 1):(nrow(data)),],
        # |xxx------> ����� ��� ����������� ��������
        'train' = data[(nrow(data) - length + 1):(nrow(data)),]
      )
    } else {
      result <- list(
        # |xxxxxx---> ����� ��� ��������
        'learn' = data[1:(nrow(data) - length),],
        # |------xxx> ����� ��� ����������� ��������
        'tain' = data[(nrow(data) - length + 1):nrow(data),]
      )
    }
  }
  return(result)
}

# ������ ������ ������� �������� ����
# �������������� ������ �� �����-��������� ���������� ������
# 
# (integer) nfold - �������� ��������� � ����������� �� ���������� ������ ����������
#
# (data frame) data - ������ ��� �������� ������
#
# (string) method - ���������� ����� ���������� �������. � ������ 'number' - ���
# ����� ���������� ������ �� ���� �������, � ������ 'percent' - ��� �������
# ������ �� ���� �������, ���������� ��� ��������
crossValidate <- function(nfold, data, method = 'number') {
  
  # ��������� ����� ����� ������, � ����������� �� ������
  nparts <- getNparts(nfold, method)
  
  # ��������� �� ������ ��������� �������� �� ������� ����� leave-one-out �����-����������
  loocv <- nrow(data) == nfold
  
  # ������� ���������� ������ ��� ������������ �������� ������
  storage <- c()
  
  # ������� ����������� ������ ����������� �������
  trainPart <- 1
  result <- list()
  while(trainPart <= nparts) {
    # �������� ������� �� �����
    prepared <- nfoldSubset(nfold, trainPart, data, method)
    learn <- prepared[[1]]
    train <- prepared[[2]]
    
    # ������ �������� ������������� ������������� ������
    fit <- glm(class ~ ., learn, family = "binomial")
    
    # ������������� ����������� � �������� �������������� �������� (class), �.�. �� 0 �� 1
    prob <- predict(object = fit, newdata = train, type = "response")
    
    # � ������ leave-on-out ����������� ������
    if(loocv) {
      storage[trainPart] <- prob
    } else {
      # � ������ ���������� ������� ������� ����� ���������� ������� ������ � AUC
      result[[trainPart]] <- modelSummary(prob, train$class)
    }
    
    # ����������� ������� ������ ����������� �������
    trainPart <- trainPart + 1
  }
  
  # � ������ leave-one-out �����-��������� ������������� �������������� ������������ �� ������� 
  # �� ������� ������������ ������� �������� ������
  if(loocv) {
    return(modelSummary(storage, data$class))
  } else {
    return(list(
      # ������� ���������� ���������� ������� ��� ���� �������
      'mean' = mean(unlist(sapply(result, "[", 'mean'))),
      # ������� ������� ROC ������ ��� ���� �������
      'AUC' = mean(unlist(sapply(result, "[", 'AUC')))
    ))
  }
}

# ������� ������ ������� �������� ������� ������������� ������������� �� ������������ ������
#
# (vector) prob - ������ ������������ �������������� ���������� ���� ��� ����� ������
#
# (vector) actual - ������ �������������� ������� ����������
modelSummary <- function(prob, actual) {
  
  # ��� ���������� ���������� ����������, ����� ������ ��������� � ���� �������, ������������� ����������� ROCR
  # ��������� �������� ������� ���� ������ (������������� ����������� + ��������� �������������� ��������)
  pred_fit <- prediction(prob, factor(actual, levels = c(0, 1)))
  
  # ������� ������������� �������
  # ��� ������ ������������ ����� ������� ������������� � ������ ���������� ������� ��� ������ "1", �.�. � ��� �������� ������
  specificity  <- performance(pred_fit, x.measure = "cutoff", measure = "spec")
  
  # ������� ���������������� �������
  # ��� ������ ������������ ����� ������� ������������� � ������ ���������� ������� ��� ������ "0", �.�. � ��� �������� ������
  sensitivity  <- performance(pred_fit, x.measure = "cutoff", measure = "sens")
  
  # ��������� ��� ����������� �� �������
  plot(specificity, col = "red", lwd = 2)
  plot(add = T, sensitivity , col = "green", lwd = 2)
  
  # ��� ����������� ������ ������������� ��������� ���������� ������� ����� ���������� ������ ������������� � ����������������
  diff <- abs(unlist(specificity@y.values) - unlist(sensitivity@y.values))
  
  # �������� ����� ������������� �� ���������� �� ������� ������� ������
  threshold <- unlist(sensitivity@x.values)[match(min(diff), diff)]
  
  # ��������� ����� �� �������
  abline(v = threshold, lwd = 2)
  
  # ��������� ���������� ����������� � ����� �������������, �������� ������ ������� ��� ���������� ������
  pred_resp  <- factor(ifelse(prob > threshold, 1, 0))
  
  # � ������ ����� ���������� ������� ������������ �������� � ����������� �������
  correct  <- ifelse(pred_resp == actual, 1, 0)
  
  # �������� ������� ��� ROC ������
  auc <- performance(pred_fit, x.measure = "cutoff", measure = "auc")@y.values[[1]]
  
  return(list(
    # ������� ����� ���������� �������
    'mean' = mean(correct),
    # ������� ��� ROC-������
    'AUC' = auc)
    )
}