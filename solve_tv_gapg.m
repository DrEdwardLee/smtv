function [ x, func_vals ] = solve_tv_gapg( A, b, m, n, C, lambda, tv_type )

if(strcmp(tv_type, 'iso'))
    h_tv_solver = @solve_isol2;
elseif(strcmp(tv_type, 'aniso'))
    h_tv_solver = @solve_l1;
else
    error('Unidentified TV type. Use "iso" or "aniso".')
end

max_iterations = 100;

func_vals = zeros(max_iterations, 1);
last_f_value = Inf;

mu = norm(b, 'fro');
mu_min = 1e-3*mu;
A_2_est = min(sqrt(sum(abs(A(:))>0)*sum(A(:).*A(:))), sum(abs(A(:))));
eta = 1;
rho = (sqrt(mu)*A_2_est + 4*sqrt(eta))^2;
% C_2_est = normest(C);
% rho = (sqrt(mu)*A_2_est + sqrt(eta)*C_2_est)^2;

% x = b(:);
x = b;

% u = C*x;
u = x*C;

y_x = x;
y_u = u;

t = 1;

At_b = reshape(imfilter(reshape(b, m, n), A', 'symmetric'), 1, m*n);

tol = 1*10^-10;

for k = 1 : max_iterations
    
    x_prev = x;
    u_prev = u;
    t_prev = t;

    At_A_x = reshape(imfilter(imfilter(reshape(y_x, m, n), A, 'symmetric'), A', 'symmetric'), 1, m*n);

%     x = y_x - 1/rho * (mu*(At_A_x - At_b) + C'*(C*y_x  - y_u));
%     x = y_x - 1/rho * (At_A_x - At_b + C'*(C*y_x  - y_u));
    x = y_x - 1/rho * (At_A_x - At_b + (y_x*C - y_u)*C');
    
    x = max(x, 0);
    x = min(x, 1);
    
%     u = reshape(h_tv_solver( reshape(y_u - (1/eta) * (y_u - C * y_x), 2, length(u)/2), (mu*lambda)/eta), length(u), 1);
%     u = reshape(h_tv_solver( reshape(y_u - (1/eta) * (y_u - C * y_x), 2, length(u)/2), lambda/eta), length(u), 1);
    u = h_tv_solver(y_u - (1/eta) * (y_u - y_x*C), (mu*lambda)/eta);


    t = (1 + sqrt(1 + 4*t_prev^2)) / 2;
    
    y_x = x + ((t_prev - 1)/t) * (x - x_prev);
    
    y_u = u + ((t_prev - 1)/t) * (u - u_prev);
    
    rat = ((2*k-2)/(2*k))^0.125; 
    mu = max(mu*(0.1*rat + 0.9), mu_min);
    rho = (sqrt(mu)*A_2_est + 4*sqrt(eta))^2;
%     rho = (sqrt(mu)*A_2_est + sqrt(eta)*C_2_est)^2;
    
    
    func_vals(k) = 0.5*norm(imfilter(reshape(x, m, n), A, 'symmetric') - reshape(b, m, n), 'fro')^2 + lambda*norm_l1(u);
    
    if (abs(last_f_value -  func_vals(k)) <= tol)
        break;
    else
        last_f_value = func_vals(k);
    end
    
end

end