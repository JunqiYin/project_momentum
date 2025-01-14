clear
close all

return_monthly=readtable('return_monthly.xlsx','ReadVariableNames',true,'PreserveVariableNames',true,'Format','auto');
market_cap_lm=readtable('me_lag.xlsx','ReadVariableNames',true,'PreserveVariableNames',true,'Format','auto');

stacked_returns = stack(return_monthly, 3:width(return_monthly), 'NewDataVariableName', 'Returns', 'IndexVariableName', 'Date');
stacked_market_cap = stack(market_cap_lm, 3:width(return_monthly), 'NewDataVariableName', 'MarketCap', 'IndexVariableName', 'Date');

merged_data = innerjoin(stacked_returns, stacked_market_cap, 'Keys', {'code', 'Date'});
merged_data = removevars(merged_data, {'name_stacked_returns', 'name_stacked_market_cap'});
merged_data = rmmissing(merged_data, 'DataVariables', {'MarketCap'});

return_m = merged_data;

frequency = [1, 3, 6, 12, 24];

[G,jdate]=findgroups(return_m.Date);
num_obs=length(jdate);

return_m.jdate=G;

mom_old=table();

for i = 3
    % frequency = 3
    for j=[i: num_obs-1]
        % pick up previous frequency(i) months returns
         temp_date=[j-i+1:j];
         start_date=j+1;
        index_i=(return_m.jdate==temp_date);
        index=logical(sum(index_i,2));
        mom_sample=return_m(index,1:end);

       % calculate the previous months' cumulative return
       [G,code]=findgroups(mom_sample.code);
       pr_return=splitapply(@(x)sum(x),mom_sample.Returns,G);
       pr_return_table=table(code,pr_return);
       % merge it back to mom_sample to enhance the vector of previous return
       
       index_r=(return_m.jdate==start_date);
       mom_r=return_m(index_r,1:end);

       mom_sample1=outerjoin(mom_r,pr_return_table,'Keys',{'code'},'MergeKeys',true,'Type','left');
       
       % merge the sample back to the full dataset for each iteration
       
       return_full=vertcat(mom_old, mom_sample1);
       
       mom_old=return_full;
        
    end

end