clear all
close all
import casadi.*

LEVEL = 1;

CROSS_COMP_MODES = [1,3,4,7];
INITIAL_HEIGHT = [0.03,0.2];
E = [1]; % TODO(anton) join height and e into 1 conditions struct
N_FE = [2,3];

% TODO(anton) please make an automatic naming generator
index = 1;

for cross_comp_mode=CROSS_COMP_MODES
    for lift=[false, true]
        for idx=1:length(INITIAL_HEIGHT)
            for e=E
                for N_fe=N_FE
                    problem_options = NosnocProblemOptions();
                    model = NosnocModel();
                    model.model_name = ['CLS1D'];
                    problem_options.irk_scheme = IRKSchemes.GAUSS_LEGENDRE;
                    problem_options.n_s = 1;
                    problem_options.cross_comp_mode = cross_comp_mode;
                    problem_options.dcs_mode = DcsMode.CLS;
                    problem_options.no_initial_impacts = 1;
                    problem_options.lift_complementarities = lift;
                    %% model defintion
                    g = 9.81;
                    x0 = [INITIAL_HEIGHT(idx);0];

                    q = SX.sym('q',1);
                    v = SX.sym('v',1);
                    model.M = 1;
                    model.x = [q;v];
                    model.e = e;
                    model.mu_f = 0;
                    model.x0 = x0;
                    model.f_v = -g;
                    model.f_c = q;
                    %% Simulation setings
                    problem_options.T = 0.1;
                    problem_options.N_finite_elements = N_fe;
                    %% generate mpcc
                    % TODO annoying serialization issues
                    %mpcc = NosnocMPCC(problem_options, model.dims, model);
                    problem_options.preprocess();
                    model.verify_and_backfill(problem_options);
                    model.generate_variables(problem_options);
                    model.generate_equations(problem_options);
                    filename = generate_problem_name(model, problem_options, idx)
                    save(['../../level', num2str(LEVEL) ,'/', char(filename), '.mat'], 'model', 'problem_options');
                    index = index+1;
                end
            end
        end
    end
end
