using UnityEngine;

public class Singleton<T> : MonoBehaviour where T : MonoBehaviour
{
    private static T _instance;

    /// <summary>
    /// Access singleton instance through this propriety.
    /// </summary>
    public static T instance
    {
        get
        {
            if (_instance == null)
            {
                _instance = (T)FindObjectOfType(typeof(T));
            }
            if (_instance == null)
            {
                Debug.Log("_instance is null");
            }
            return _instance;
        }
    }
}
