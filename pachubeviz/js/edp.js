
var edp = {
	tarifa_simples: 0.1393,
	tarifa_bihorario_vazia: 0.0833,
	tarifa_bihorario_fora_de_vazio: 0.1551,
	simples: function(time) { return edp.tarifa_simples; },
	bihorario_diario: function(time) {
		if(time.getHours() < 8) 
			return edp.tarifa_bihorario_vazia;
		if(time.getHours() < 22) 
			return edp.tarifa_bihorario_fora_de_vazio;
		return edp.tarifa_bihorario_vazia;
	},
	bihorario_semanal: function(time) {
				   if(time.getDay() == 0) { // Sunday
					   return edp.tarifa_bihorario_vazia;
				   } else if(time.getDay() == 6) { //Saturday
					   var diff = new Date(time);
					   diff.setHours(9);
					   diff.setMinutes(30);
					   if(time < diff)
						   return edp.tarifa_bihorario_vazia;
					   if(time.getHours() < 7) 
						   return edp.tarifa_bihorario_fora_de_vazio;
					   diff.setHours(18)
						   if(time < diff)
							   return edp.tarifa_bihorario_vazia;
					   if(time.getHours() < 22) 
						   return edp.tarifa_bihorario_fora_de_vazio;
					   return edp.tarifa_bihorario_vazia;
				   } else if(time.getHours() < 7) { 
					   return edp.tarifa_bihorario_vazia;
				   }
				   return edp.tarifa_bihorario_fora_de_vazio;
			   }
}
