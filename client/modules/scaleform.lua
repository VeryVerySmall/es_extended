function ESX.Scaleform.ShowFreemodeMessage(title, msg, sec)
	local scaleform = ESX.Scaleform.Utils.RequestScaleformMovie('MP_BIG_MESSAGE_FREEMODE')
	BeginScaleformMovieMethod(scaleform, 'SHOW_SHARD_WASTED_MP_MESSAGE')
	PushScaleformMovieMethodParameterString(title)
	PushScaleformMovieMethodParameterString(msg)
	EndScaleformMovieMethod()
	while sec > 0 do
		Citizen.Wait(0)
		sec = sec - 0.01
		DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
	end
	SetScaleformMovieAsNoLongerNeeded(scaleform)
end

function ESX.Scaleform.ShowBreakingNews(title, msg, bottom, sec)
	local scaleform = ESX.Scaleform.Utils.RequestScaleformMovie('BREAKING_NEWS')
	BeginScaleformMovieMethod(scaleform, 'SET_TEXT')
	PushScaleformMovieMethodParameterString(msg)
	PushScaleformMovieMethodParameterString(bottom)
	EndScaleformMovieMethod()
	BeginScaleformMovieMethod(scaleform, 'SET_SCROLL_TEXT')
	PushScaleformMovieMethodParameterInt(0)
	PushScaleformMovieMethodParameterInt(0)
	PushScaleformMovieMethodParameterString(title)
	EndScaleformMovieMethod()
	BeginScaleformMovieMethod(scaleform, 'DISPLAY_SCROLL_TEXT')
	PushScaleformMovieMethodParameterInt(0)
	PushScaleformMovieMethodParameterInt(0)
	EndScaleformMovieMethod()
	while sec > 0 do
		Citizen.Wait(0)
		sec = sec - 0.01
		DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
	end
	SetScaleformMovieAsNoLongerNeeded(scaleform)
end

function ESX.Scaleform.ShowPopupWarning(title, msg, bottom, sec)
	local scaleform = ESX.Scaleform.Utils.RequestScaleformMovie('POPUP_WARNING')
	BeginScaleformMovieMethod(scaleform, 'SHOW_POPUP_WARNING')
	PushScaleformMovieMethodParameterFloat(500.0)
	PushScaleformMovieMethodParameterString(title)
	PushScaleformMovieMethodParameterString(msg)
	PushScaleformMovieMethodParameterString(bottom)
	PushScaleformMovieMethodParameterBool(true)
	EndScaleformMovieMethod()
	while sec > 0 do
		Citizen.Wait(0)
		sec = sec - 0.01
		DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
	end
	SetScaleformMovieAsNoLongerNeeded(scaleform)
end

function ESX.Scaleform.ShowTrafficMovie(sec)
	local scaleform = ESX.Scaleform.Utils.RequestScaleformMovie('TRAFFIC_CAM')
	BeginScaleformMovieMethod(scaleform, 'PLAY_CAM_MOVIE')
	EndScaleformMovieMethod()
	while sec > 0 do
		Citizen.Wait(0)
		sec = sec - 0.01
		DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
	end
	SetScaleformMovieAsNoLongerNeeded(scaleform)
end

function ESX.Scaleform.Utils.RequestScaleformMovie(movie)
	local scaleform = RequestScaleformMovie(movie)
	while not HasScaleformMovieLoaded(scaleform) do
		Citizen.Wait(0)
	end
	return scaleform
end