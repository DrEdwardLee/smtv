function [ A ] = smtv( N_pixel, N_images, images, R, lambda, lambda_2, good_entries, A)
%% Solves the following
%
% min_{A}   lambda * TV(A) + 1/2 | (A - I_i) D_i |^2
%
%   via ADMM
%
% Created by Stephen Tierney
% stierney@csu.edu.au
%

warning('off','all')

max_iterations = 500;

func_vals = zeros(max_iterations,1);

mu = 0.1;

mu_max = 10;
gamma_0 = 1.1;

normfR = norm(R, 'fro');

% Technically the fro norm should be used
% However convergence is too slow
% rho = norm(R, 'fro');
rho = (normest(R)^2) * 1.1;

if ~exist('A', 'var')
      A = zeros(size(images{1},1), N_pixel);
end

U = zeros(size(images{1},1), size(R, 2));

Y = zeros(size(U));

D = cell(1, N_images);

for k = 1 : N_images
    D{k} = lambda_2(k) * spdiags(good_entries{k}', 0, N_pixel, N_pixel);
%     D{k} = spdiags(good_entries{k}', 0, N_pixel, N_pixel);
end

tol_1 = 1*10^-2;
tol_2 = 1*10^-4;

for k = 1 : max_iterations
    
    prev_A = A;
    prev_U = U;
    
    % Update A

    A_rhs = mu*(prev_A * R - prev_U - 1/mu * Y) * R';
    A_lhs = zeros(size(A));
    f_rhs = zeros(N_pixel,1);
    for j = 1 : N_images
%         A_lhs = A_lhs + lambda_2(j) * ( (A - images{j})*D{j} ) * D{j}';
        A_lhs = A_lhs + ( (A - images{j})*D{j} ) * D{j}';
        f_rhs(j, 1) = 0.5 * norm( (A - images{j})*D{j}, 'fro')^2;
    end
    A = prev_A - 1/rho * (A_lhs + A_rhs);
    
% %     A = max(A, 0);
% %     A = min(A, 1);
    
    % Update U
    U = solve_l1(prev_A * R - 1/mu * Y , lambda / mu);
    
    % Update Y
    Y = Y + mu * (U - A*R);
    
    m = mu * sqrt(rho) * max([norm(A - prev_A,'fro'), norm(U - prev_U,'fro')]) / normfR;
    
    % Update mu
    if m < tol_2
        gamma = gamma_0;
    else
        gamma = 1;
    end
     
    mu = min(mu_max, gamma * mu);    

    func_vals(k) = lambda*norm_l1(A*R) + sum(f_rhs);
    
    % Check convergence
    if ( norm(U - A*R, 'fro')/normfR < tol_1 && m < tol_2)
        break;
    end
    
end

warning('on','all')

end