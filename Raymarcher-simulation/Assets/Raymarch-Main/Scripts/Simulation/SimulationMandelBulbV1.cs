using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class SimulationMandelBulbV1 : MonoBehaviour
{
    [SerializeField] ColorPicker MandelColP;
    [SerializeField] ColorPicker BackgroundColorP;
    [SerializeField] public Color MandelCol;
    [SerializeField] public Color BackgroundColor;
    [SerializeField] Material mandelMat;
    [SerializeField] Slider zoomSlider;
    [SerializeField] Slider powerSlider;
    [SerializeField] Slider iterationSlider;
    [SerializeField] Slider outlineSlider;
    [SerializeField] Toggle enableSpeedSlider;
    [SerializeField] Slider speedSlider;
    private void OnEnable()
    {
        UpdateManager.onUpdate += _Update;
    }
    private void OnDisable()
    {
        UpdateManager.onUpdate -= _Update;
    }
    void _Update()
    {
        MandelCol = MandelColP.col;
        BackgroundColor = BackgroundColorP.col;
        mandelMat.SetVector("_MandelColor", MandelCol);
        mandelMat.SetVector("_BackgroundColor", BackgroundColor);
        mandelMat.SetFloat("_Zoom", (zoomSlider.maxValue - zoomSlider.value));
        mandelMat.SetFloat("_Power", powerSlider.value);
        mandelMat.SetFloat("_Iteration", iterationSlider.value);
        mandelMat.SetFloat("_Outline", outlineSlider.value);

        if (enableSpeedSlider.isOn)
            mandelMat.SetFloat("_Speed", speedSlider.value);
        else
            mandelMat.SetFloat("_Speed", 0);


    }
}
