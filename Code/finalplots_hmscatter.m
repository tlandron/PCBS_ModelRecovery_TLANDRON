function finalplots_hmscatter(f_dout, f_nsubjsubset, f_nsim, f_str_nsubjsubset, f_formatSpec_file, f_formatSpec_title, ...
                                      f_toplot, f_strtoplot, f_strtoplot_short, f_ylabel)
    % Plot the an scatterplot of f_toplot (mean probability of reversal/mean choice variability or    ...
    %      correlation coefficients or shared variance values between probability of reversal and     ...
    %      choice variability) for each subject subset.
    % Input:  'f_dout'                        folder for data (dout)
    %         'f_nsubjsubset'                 subsets of participant (nsubjsubset)
    %         'f_nsim'                        number of simulations (nsim)
    %         'f_str_nsubjsubset'             string version of nsubjsubset (str_nsubjsubset)
    %         'f_formatSpec_file'             saved figure string format (formatSpec_file)
    %         'f_formatSpec_title'            title string format (formatSpec_title)
    %         'f_toplot'                      variable to be plotted (e.g., corr or sharedvar)
    %         'f_strtoplot'                   string full name of the variable to be plotted ...
    %                                         (e.g., 'Correlation coefficients' or 'Shared variance')
    %         'f_strtoplot_short'             string short name of the variable to be plotted ...
    %                                         (e.g., 'corr' or 'sharedvar')     
    %         'f_ylabel'                      y label (e.g, math name for corr: 'r', sharedvar: 'R^2')
    % Output: one figure saved (for either prev or beta)

    lgd = cell(length(f_nsubjsubset), 1); % to create an 'automatic' legend corresponding with each subset
    for irevindexsubset = 1:length(f_nsubjsubset)
       lgd{irevindexsubset} = sprintf('%d subjects', f_nsubjsubset(irevindexsubset));
    end
    
    
    h = figure;
    hold on;
    title(sprintf(f_formatSpec_title, f_strtoplot, f_nsim))
    
    for i = 1:length(f_toplot)
        scatter(0, f_toplot(i))
    end

    m = mean(f_toplot);
    hline = refline([0 m]);
    hline.Color = 'r';

    ax1 = gca;                   % to get current axes
    ax1.YAxis.Visible = 'on' ;   % to keep y-axis
    ax1.XAxis.Visible = 'off';   % to remove x-axis
    ylabel(f_ylabel);
    legend(lgd)
    hold off
    
    
    name_fig = sprintf(f_formatSpec_file, f_dout, ['fig_',f_strtoplot_short], ...
                                          f_nsim, f_str_nsubjsubset, '.png');
    saveas(h, name_fig)
end
