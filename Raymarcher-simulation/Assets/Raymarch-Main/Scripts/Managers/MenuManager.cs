using DG.Tweening;
using UnityEngine;

public class MenuManager : MonoBehaviour
{
    [SerializeField] RectTransform SideParameters;
    [SerializeField] float cycleLength = 2;
    bool onScreen = true;
    public void Toggle()
    {
        print("Toggle");
        if (onScreen)
        {
           SideParameters.DOAnchorPos(SideParameters.anchoredPosition + new Vector2(300,0), cycleLength);
        }
        else
        {
            SideParameters.DOAnchorPos(SideParameters.anchoredPosition - new Vector2(300,0), cycleLength);
        }
        onScreen = !onScreen;
    }


}
