# EM algorithm and Online EMA


argv <- commandArgs(T);
if (length(argv[argv=="faithful"])) {
	# Old Faithful dataset ���擾���Đ��K��
	data("faithful");
	xx <- scale(faithful, apply(faithful, 2, mean), apply(faithful, 2, sd));
	K <- 2;
} else {
	# �R�������R��̃e�X�g�f�[�^�𐶐�
	library(MASS);
	xx <- rbind(
		mvrnorm(100, c(1,3,0), matrix(c(0.7324,-0.9193,0.5092,-0.9193,2.865,-0.2976,0.5092,-0.2976,3.294),3)),
		mvrnorm(150, c(4,-1,-2), matrix(c(2.8879,-0.2560,0.5875,-0.2560,3.0338,1.2960,0.5875,1.2960,1.7438),3)),
		mvrnorm(200, c(0,2,1), matrix(c(3.1178,1.7447,0.6726,1.7447,2.3693,0.0521,0.6726,0.0521,0.7917),3))
	);
	xx <- xx[sample(nrow(xx)),]
	K <- 3;
}
N <- nrow(xx);


# �p�����[�^�̏�����(���ρA�����U�A������)
init_param <- function(K, D) {
	sig <- list();
	for(k in 1:K) sig[[k]] <- diag(K);
	list(mu = matrix(rnorm(K * D), D), mix = numeric(K)+1/K, sig = sig);
}

# ���������K���z���x�֐�
dmnorm <- function(x, mu, sig) {
	D <- length(mu);
	1/((2 * pi)^D * sqrt(det(sig))) * exp(- t(x-mu) %*% solve(sig) %*% (x-mu) / 2)[1];
}

# EM �A���S���Y���� E �X�e�b�v
Estep <- function(xx, param) {
	K <- nrow(param$mu);
	t(apply(xx, 1, function(x){
		numer <- param$mix * sapply(1:K, function(k) {
			dmnorm(x, param$mu[k,], param$sig[[k]])
		});
		numer / sum(numer);
	}))
}

# EM �A���S���Y���� M �X�e�b�v
Mstep <- function(xx, gamma_nk) {
	K <- ncol(gamma_nk);
	D <- ncol(xx);
	N <- nrow(xx);

	N_k <- colSums(gamma_nk);
	new_mix <- N_k / N;
	new_mu <- (t(gamma_nk) %*% xx) / N_k;

	new_sig <- list();
	for(k in 1:K) {
		sig <- matrix(numeric(D^2), D);
		for(n in 1:N) {
			x <- xx[n,] - new_mu[k,];
			sig <- sig + gamma_nk[n, k] * (x %*% t(x));
		}
		new_sig[[k]] <- sig / N_k[k]
	}

	list(mu=new_mu, sig=new_sig, mix=new_mix);
}

# �ΐ��ޓx�֐�
Likelihood <- function(xx, param) {
	K <- nrow(param$mu);
	sum(apply(xx, 1, function(x){
		log(sum(param$mix * sapply(1:K, function(k) dmnorm(x, param$mu[k,], param$sig[[k]]))));
	}))
}

OnlineEM <- function(xx, m, param) {
	N <- nrow(xx);
	K <- nrow(param$mu);

	new_gamma <- param$mix * sapply(1:K, function(k) {
		dmnorm(xx[m, ], param$mu[k,], param$sig[[k]]);
	});
	new_gamma <- new_gamma / sum(new_gamma);
	delta <- new_gamma - param$gamma[m,];
	param$gamma[m,] <- new_gamma;

	param$mix <- param$mix + delta / N;
	N_k <- param$mix * N;
	for(k in 1:K) {
		x <- xx[m,] - param$mu[k,];
		d <- delta[k] / N_k[k];
		param$mu[k,] <- param$mu[k,] + d * x;
		param$sig[[k]] <- (1 - d) * (param$sig[[k]] + d * x %*% t(x));
	}
	param;
}


for (n in 1:10) {
	# �����l
	param0 <- init_param(K, ncol(xx));

	# normal EM
	timing <- system.time({
		param <- param0;

		# ��������܂ŌJ��Ԃ�
		likeli <- -999999;
		for (j in 1:100) {
			gamma_nk <- Estep(xx, param);
			param <- Mstep(xx, gamma_nk);

			cat(sprintf(" %d: %.3f\n", j, (l <- Likelihood(xx, param))));
			if (l - likeli < 0.001) break;
			likeli <- l;
		}
	});
	cat(sprintf("Normal %d:convergence=%d, likelihood=%.4f, %1.2fsec\n", n, j, likeli, timing[3]));
	#print(param$mu);

	# incremental EM
	timing <- system.time({
		param <- param0;

		# �ŏ��̈���͒ʏ�� EM
		gamma_nk <- Estep(xx, param);
		param <- Mstep(xx, gamma_nk);
		param$gamma <- gamma_nk;

		# online EM
		likeli <- -999999;
		for (j in 2:100) {
			randomlist <- sample(1:N);
			for(m in randomlist) param <- OnlineEM(xx, m, param);

			cat(sprintf(" %d: %.3f\n", j, (l <- Likelihood(xx, param))));
			if (l - likeli < 0.001) break;
			likeli <- l;
		}
	});
	cat(sprintf("Online %d:convergence=%d, likelihood=%.4f, %1.2fsec\n", n, j, likeli, timing[3]));
	#print(param$mu);
}

# plot(xx, col=rgb(gamma_nk[,1],0,gamma_nk[,2]), xlab=paste(sprintf("%1.3f",t(param$mu)),collapse=","), ylab="");
# points(param$mu, pch = 8);

