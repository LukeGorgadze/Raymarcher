using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System;
using UnityEngine.Events;


public class ColorPicker : MonoBehaviour
{
    [SerializeField] public Color col;
    public TextMeshProUGUI DebugText;
    RectTransform _rect;
    Texture2D _colorTexture;
    private void OnEnable()
    {
        UpdateManager.onUpdate += _Update;
    }
    private void OnDisable()
    {
        UpdateManager.onUpdate -= _Update;
    }
    void Start()
    {
        _rect = GetComponent<RectTransform>();
        _colorTexture = GetComponent<Image>().mainTexture as Texture2D;
    }

    void _Update()
    {
        if (RectTransformUtility.RectangleContainsScreenPoint(_rect, Input.mousePosition))
        {
            Vector2 delta;
            RectTransformUtility.ScreenPointToLocalPointInRectangle(_rect, Input.mousePosition, null, out delta);

            string debug = "mousePosition=" + Input.mousePosition + "<br>delta=" + delta;

            float width = _rect.rect.width;
            float height = _rect.rect.height;

            delta += new Vector2(width / 2, height / 2);
            debug += "<br>offsetDelta=" + delta;

            float x = Mathf.Clamp(delta.x / width, 0, 1);
            float y = Mathf.Clamp(delta.y / height, 0, 1);

            debug += "<br>x=" + x + " y=" + y;

            int texX = Mathf.RoundToInt(x * _colorTexture.width);
            int texY = Mathf.RoundToInt(y * _colorTexture.height);

            debug += "<br>xX=" + texX + " yY=" + texY;

            Color color = _colorTexture.GetPixel(texX, texY);
            if (color.a == 0) return;
            DebugText.color = color;

            DebugText.text = debug;

            if (Input.GetMouseButton(0))
            {
                col = color;
            }
        }
    }
}
