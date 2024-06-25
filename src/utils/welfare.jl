function utility(cons, emuc)
    if emuc == 1
        log(cons)
    else
        (cons^(1 - emuc)) / (1 - emuc)
    end
end

function invutility(util, emuc)
    if emuc == 1
        exp(util)
    else
        (util * (1 - emuc))^(1 / (1 - emuc))
    end
end

function weighted_costs(cons_percap_consumption_0_focus, emuc_utilityconvexity, cc, cons_percap_consumption, costs_percap)
    # Weighted costs (Page 23 of Hope 2009)
    ((cons_percap_consumption_0_focus^emuc_utilityconvexity) / (1 - emuc_utilityconvexity)) * (cons_percap_consumption^(1 - emuc_utilityconvexity) - (cons_percap_consumption - costs_percap < 0.01 * cons_percap_consumption_0_focus ? 0.01 * cons_percap_consumption_0_focus : cons_percap_consumption - costs_percap)^(1 - emuc_utilityconvexity))
end

function df_utilitydiscountfactor(discountrate, y_year, y_year_0)
    (1 + discountrate / 100)^(-(y_year - y_year_0))
end



