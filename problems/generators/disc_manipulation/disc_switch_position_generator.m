clear all
close all
import casadi.*

LEVEL = 3; % MAYBE 4

CROSS_COMP_MODES = [1,3,4,7];
N_FE = [3];
N_STAGES = [20,23,31];

% TODO(anton) please make an automatic naming generator
index = 1;

for cross_comp_mode=CROSS_COMP_MODES
    for lift=[false, true]
        for N_stg=N_STAGES
            for N_fe=N_FE
                problem_options = NosnocProblemOptions();
                model = NosnocModel();
                model.model_name = ['DSCSP'];
                
                problem_options.irk_scheme = IRKSchemes.RADAU_IIA;
                problem_options.n_s = 1;  
                problem_options.time_freezing = 1;
                problem_options.pss_lift_step_functions = 0;
                problem_options.lift_complementarities = lift;
                problem_options.cross_comp_mode = cross_comp_mode;
                %% model parameters
                m1 = 2;
                m2 = 1;
                r1 = 0.3;
                r2 = 0.2;

                
                q10 = [-1; 0];
                q20 = [1;0];
                v10 = [0;0];
                v20 = [0;0];

                q_target1 = q20;
                q_target2 = q10;

                x0 = [q10;q20;v10;v20];
                ubx = [10; 10;10; 10; 5; 5; 5; 5]; 
                lbx = -ubx;
                ubu = [20;20];
                lbu= -ubu;

                x_ref = [q_target1;q_target2;zeros(4,1)];
                u_ref = [0;0];

                Q = diag([5;5;10;10;0*ones(4,1)]);
                R = diag([0.1 0.1]);
                Q_terminal = 100*Q;
                
                %% Symbolic variables and bounds
                q = SX.sym('q',4);
                v = SX.sym('v',4); 
                u = SX.sym('u',2);

                q1 = q(1:2);
                q2 = q(3:4);
                v1 = v(1:2);
                v2 = v(3:4);
                x = [q;v];

                problem_options.T = 3;
                problem_options.N_stages = N_stg;
                problem_options.N_finite_elements  = N_fe;
                model.x = x;
                model.u = u;
                model.e = 0;
                model.mu_f = 0;
                model.a_n = 10;
                model.x0 = x0; 
                model.dims.n_dim_contact = 2;

                cv = 2;
                eps = 1e-1;
                f_drag = cv*[v1/norm(v1+eps);v2/norm(v2+eps)];

                model.M = diag([m1;m1;m2;m2]); % inertia/mass matrix;
                model.f_v = [u;...
                    zeros(2,1)]-f_drag;
                model.f_c = [norm(q1-q2)^2-(r1+r2)^2];
                % box constraints on controls and states
                model.lbu = lbu;
                model.ubu = ubu;
                model.lbx = lbx;
                model.ubx = ubx;
                %% Objective
                model.f_q = 1*(x-x_ref)'*Q*(x-x_ref)+ u'*R*u;
                model.f_q_T = (x-x_ref)'*Q_terminal*(x-x_ref);
                
                %% generate mpcc
                % TODO annoying serialization issues
                %mpcc = NosnocMPCC(problem_options, model.dims, model);
                problem_options.preprocess();
                model.verify_and_backfill(problem_options);
                model.generate_variables(problem_options);
                model.generate_equations(problem_options);
                filename = generate_problem_name(model, problem_options, 1)
                save(['../../level', num2str(LEVEL) ,'/', char(filename), '.mat'], 'model', 'problem_options');
                index = index+1;
            end
        end
    end
end
