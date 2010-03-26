# Old Faithful dataset ���擾���Đ��K��
data("faithful");
xx <- scale(faithful, apply(faithful, 2, mean), apply(faithful, 2, sd));

# 1. �p�����[�^������������B
first_param <- function(xx, init_param, K) {
	D <- ncol(xx);
	N <- nrow(xx)
	param <- list(
	    alpha = numeric(K) + init_param$alpha + N / K,
	    beta  = numeric(K) + init_param$beta + N / K,
	    nyu   = numeric(K) + init_param$nyu + N / K,
	    W     = list(),
	    m     = matrix(rnorm(K * D), nrow=K)
	);
	for(k in 1:K) param$W[[k]] <- diag(D);
	param;
}


# 2. (10.65)�`(10.67) �ɂ�蕉�S�� r_nk �𓾂�
VB_Estep <- function(xx, param) {
	K <- length(param$alpha);
	D <- ncol(xx);

	# (10.65)
	ln_lambda <- sapply(1:K, function(k) {
		sum(digamma((param$nyu[k] + 1 - 1:D) / 2)) + D * log(2) + log(det(param$W[[k]]));
	});

	# (10.66)
	ln_pi <- exp(digamma(param$alpha) - digamma(sum(param$alpha)));

	# (10.67)
	t(apply(xx, 1, function(x){
		quad <- sapply(1:K, function(k) {
			xm <- x - param$m[k,];
			t(xm) %*% param$W[[k]] %*% xm;
		});
		ln_rho <- ln_pi + ln_lambda / 2 - D / 2 / param$beta - param$nyu / 2 * quad;
		ln_rho <- ln_rho - max(ln_rho);   # exp �� Inf �ɂ����Ȃ��悤
		rho <- exp(ln_rho);
		rho / sum(rho);
	}));
}


# 3. r_nk ��p���āA(10.51)�`(10.53) �ɂ�蓝�v�� N_k, x_k, S_k �����߁A
# ������p���āA(10.58), (10.60)�`(10.63) �ɂ��p�����[�^ ��_k, m_k, ��_k, ��_k, W_k ���X�V����B
VB_Mstep <- function(xx, init_param, resp) {
	K <- ncol(resp);
	D <- ncol(xx);
	N <- nrow(xx);

	# (10.51)
	N_k <- colSums(resp);

	# (10.52)
	x_k <- (t(resp) %*% xx) / N_k;

	# (10.53)
	S_k <- list();
	for(k in 1:K) {
		S <- matrix(numeric(D * D), D);
		for(n in 1:N) {
			x <- xx[n,] - x_k[k,];
			S <- S + resp[n,k] * ( x %*% t(x) );
		}
		S_k[[k]] <- S / N_k[k];
	}

	param <- list(
	  alpha = init_param$alpha + N_k,    # (10.58)
	  beta  = init_param$beta + N_k,     # (10.60)
	  nyu   = init_param$nyu + N_k,      # (10.63)
	  W     = list()
	);

	# (10.61)
	param$m <- (init_param$beta * init_param$m + N_k * x_k) / param$beta;

	# (10.62)
	W0_inv <- solve(init_param$W);
	for(k in 1:K) {
		x <- x_k[k,] - init_param$m[k,];
		Wk_inv <- W0_inv + N_k[k] * S_k[[k]] + init_param$beta * N_k[k] * ( x %*% t(x)) / param$beta[k];
		param$W[[k]] <- solve(Wk_inv);
	}

	param;
}


K <- 6;
init_param <- list(alpha=0.001, beta=25, nyu=ncol(xx));
param <- first_param(xx, init_param, K);
init_param$W <- param$W[[1]];
init_param$m <- param$m;



# �ȍ~�A��������܂ŌJ��Ԃ�
resp <- VB_Estep(xx, param);
#plot(xx, col=rgb(resp[,1],0,resp[,2]), xlab=paste(sprintf(" %1.3f",t(param$m)),collapse=","), ylab="");
#points(param$m, pch = 8);
param <- VB_Mstep(xx, init_param, resp);

